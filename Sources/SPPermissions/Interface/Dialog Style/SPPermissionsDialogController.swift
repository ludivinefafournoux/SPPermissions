// The MIT License (MIT)
// Copyright © 2020 Ivan Vorobei (hello@ivanvorobei.by)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import UIKit

#if os(iOS)

public class SPPermissionsDialogController: UIViewController, SPPermissionsControllerInterface {
    
    public weak var dataSource: SPPermissionsDataSource?
    public weak var delegate: SPPermissionsDelegate?
    
    public var titleText = Text.header
    public var headerText = Text.sub_header
    public var footerText = Text.comment
    public var bounceAnimationEnabled = true
    
    private let dialogView = SPPermissionsDialogView()
    private let backgroundView = SPPermissionsDialogGradeBlurView()
    
    private var permissions: [SPPermissions.Permission]
    
    // MARK: - Init
    
    init(_ permissions: [SPPermissions.Permission]) {
        self.permissions = permissions
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    // MARK: - Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(backgroundView)
        
        // Dialog View
        
        dialogView.titleLabel.text = titleText
        dialogView.subtitleLabel.text = headerText.uppercased()
        dialogView.alpha = 0
        dialogView.tableView.dataSource = self
        dialogView.tableView.delegate = self
        dialogView.tableView.register(SPPermissionsDialogTableFooterView.self, forHeaderFooterViewReuseIdentifier: SPPermissionsDialogTableFooterView.id)
        dialogView.tableView.register(SPPermissionsTableViewCell.self, forCellReuseIdentifier: SPPermissionsTableViewCell.id)
        dialogView.closeButton.addTarget(self, action: #selector(self.dimissWithDialog), for: .touchUpInside)
        view.addSubview(dialogView)
        
        // Animator
        
        animator = UIDynamicAnimator(referenceView: view)
        snapBehavior = UISnapBehavior(item: dialogView, snapTo: dialogCenter)
        let panGesture = UIPanGestureRecognizer.init(target: self, action: #selector(self.handleGesture(sender:)))
        panGesture.maximumNumberOfTouches = 1
        dialogView.addGestureRecognizer(panGesture)
        
        // Observer
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @objc func applicationDidBecomeActive() {
        dialogView.tableView.reloadData()
    }
    
    // MARK: - Layout
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundView.frame = view.bounds
        dialogView.layout(in: view)
        
        if bounceAnimationEnabled {
            snapBehavior.snapPoint = dialogCenter
        } else {
            dialogView.center = dialogCenter
        }
    }
    
    private var dialogCenter: CGPoint {
        let width = view.frame.width - view.layoutMargins.left - view.layoutMargins.right
        let height = view.frame.height - view.layoutMargins.top - view.layoutMargins.bottom
        return CGPoint(x: view.layoutMargins.left + width / 2, y: view.layoutMargins.top + height / 2)
    }
    
    // MARK: - Helpers
    
    public func present(on controller: UIViewController) {
        animator.removeAllBehaviors()
        dialogView.transform = .identity
        dialogView.center = CGPoint.init(x: dialogCenter.x, y: dialogCenter.y * 1.2)
        modalPresentationStyle = .overCurrentContext
        controller.present(self, animated: false, completion: {
            UIView.animate(withDuration: 0.3, animations: {
                self.backgroundView.setGradeAlpha(0.07)
                self.backgroundView.setBlurRadius(4)
            }, completion: nil)
            UIView.animate(withDuration: 0.3, delay: 0.21, animations: {
                self.dialogView.alpha = 1
            }, completion: nil)
            Delay.wait(0.21, closure: { [weak self] in
                guard let self = self else { return }
                if self.bounceAnimationEnabled {
                    self.animator.addBehavior(self.snapBehavior)
                }
            })
        })
    }
    
    @objc func process(button: SPPermissionsActionButton) {
        guard let permission = button.permission else { return }
        permission.request { [weak self] in
            
            guard let self = self else { return }
            if let cell = button.superview as? SPPermissionsTableViewCell {
                cell.updateInterface(animated: true)
            }
            
            let authorized = permission.authorized
            if authorized { Haptic.impact(.light) }
            
            // Update `.locationWhenInUse` if allowed `.locationAlwaysAndWhenInUse`
            
            if permission.type == .locationAlways {
                if self.permissions.contains(where: { $0.type == .locationWhenInUse }) {
                    if let index = self.permissions.firstIndex(where: { $0.type == .locationWhenInUse }) {
                        if let cell = self.dialogView.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? SPPermissionsTableViewCell {
                            cell.updateInterface(animated: true)
                        }
                    }
                }
            }
            
            // Check if all permissions allowed
            
            let allowedPermissions = self.permissions.filter { $0.authorized }
            if allowedPermissions.count == self.permissions.count {
                Delay.wait(0.2, closure: {
                    self.dismiss(animated: true)
                })
            }
            
            if permission.authorized {
                self.delegate?.didAllowPermission(permission)
            } else {
                self.delegate?.didDeniedPermission(permission)
                
                // Delay using for fix animation freeze.
                
                Delay.wait(0.3, closure: { [weak self] in
                    guard let self = self else { return }
                    Presenter.presentAlertAboutDeniedPermission(permission, dataSource: self.dataSource, on: self)
                })
            }
        }
    }
    
    @objc func dimissWithDialog() {
        dismiss(withDialog: true)
    }
    
    public func dismiss(withDialog: Bool) {
        if withDialog {
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .beginFromCurrentState, animations: {
                self.animator.removeAllBehaviors()
                self.dialogView.transform = CGAffineTransform.init(scaleX: 0.9, y: 0.9)
                self.dialogView.alpha = 0
            }, completion: nil)
        }
        UIView.animate(withDuration: 0.3, animations: {
            self.backgroundView.setGradeAlpha(0)
            self.backgroundView.setBlurRadius(0)
        }, completion: { finished in
            self.dismiss(animated: false, completion: nil)
        })
    }
    
    public override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: {
            completion?()
            self.delegate?.didHidePermissions(self.permissions)
        })
    }
    
    // MARK: - Animator
    
    private var animator = UIDynamicAnimator()
    private var attachmentBehavior : UIAttachmentBehavior!
    private var gravityBehaviour : UIGravityBehavior!
    private var snapBehavior : UISnapBehavior!
    
    @objc func handleGesture(sender: UIPanGestureRecognizer) {
        
        guard bounceAnimationEnabled else {
            return
        }
        
        let location = sender.location(in: view)
        let boxLocation = sender.location(in: dialogView)
        
        switch sender.state {
        case .began:
            animator.removeAllBehaviors()
            let centerOffset = UIOffset(horizontal: boxLocation.x - dialogView.bounds.midX, vertical: boxLocation.y - dialogView.bounds.midY);
            attachmentBehavior = UIAttachmentBehavior(item: dialogView, offsetFromCenter: centerOffset, attachedToAnchor: location)
            attachmentBehavior.frequency = 0
            animator.addBehavior(attachmentBehavior)
        case .changed:
            attachmentBehavior.anchorPoint = location
        case .ended:
            animator.removeBehavior(attachmentBehavior)
            animator.addBehavior(snapBehavior)
            let translation = sender.translation(in: view)
            if translation.y > 100 {
                animator.removeAllBehaviors()
                gravityBehaviour = UIGravityBehavior(items: [dialogView])
                gravityBehaviour.gravityDirection = CGVector.init(dx: 0, dy: 10)
                animator.addBehavior(gravityBehaviour)
                dismiss(withDialog: false)
            }
        default:
            break
        }
    }
}

// MARK: - Table Data Source & Delegate

extension SPPermissionsDialogController: UITableViewDataSource, UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return permissions.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SPPermissionsTableViewCell.id, for: indexPath) as! SPPermissionsTableViewCell
        let permission = permissions[indexPath.row]
        cell.defaultConfigure(for: permission)
        cell.permissionDescriptionLabel.font = UIFont.preferredFont(forTextStyle: .body, weight: .regular, addPoints: -1)
        dataSource?.configure(cell, for: permission)
        cell.permissionButton.addTarget(self, action: #selector(self.process(button:)), for: .touchUpInside)
        cell.updateInterface(animated: false)
        return cell
    }
    
    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: SPPermissionsDialogTableFooterView.id) as! SPPermissionsDialogTableFooterView
        view.titleLabel.text = footerText
        view.contentView.backgroundColor = tableView.backgroundColor
        return view
    }
}

#endif

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

public class SPPermissionsTableViewCell: UITableViewCell {
    
    public let permissionTitleLabel = UILabel()
    public let permissionDescriptionLabel = UILabel()
    public let permissionButton = SPPermissionsActionButton()
    public let permissionDrawIconView = SPPermissionsDrawIconView()
    
    public let permissionIconImageView = UIImageView()
    private let permissionIconContainerView = UIView()
    
    static var id = "SPPermissionsTableViewCell"
    
    // MARK: - Init
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commonInit() {
        let verticalSpace: CGFloat = 16
        contentView.layoutMargins = .init(top: verticalSpace, left: 0, bottom: verticalSpace, right: 0)
        
        permissionTitleLabel.numberOfLines = 0
        permissionTitleLabel.textColor = UIColor.Compability.label
        permissionTitleLabel.font = UIFont.preferredFont(forTextStyle: .title2, weight: .semibold)
        addSubview(permissionTitleLabel)
        
        permissionDescriptionLabel.numberOfLines = 0
        permissionDescriptionLabel.textColor = UIColor.Compability.secondaryLabel
        permissionDescriptionLabel.font = UIFont.preferredFont(forTextStyle: .body)
        addSubview(permissionDescriptionLabel)
        
        addSubview(permissionButton)
        
        permissionIconContainerView.addSubview(permissionDrawIconView)
        permissionIconContainerView.addSubview(permissionIconImageView)
        addSubview(permissionIconContainerView)
        
        insetsLayoutMarginsFromSafeArea = false
        contentView.insetsLayoutMarginsFromSafeArea = false
    }
    
    // MARK: - Lifecycle
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        permissionTitleLabel.text = nil
        permissionDescriptionLabel.text = nil
        permissionButton.removeTarget(nil, action: nil, for: .allEvents)
        permissionIconImageView.image = nil
        permissionIconImageView.isHidden = true
        permissionDrawIconView.isHidden = false
    }
    
    // MARK: - Layout
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        // Icons
        
        permissionIconContainerView.frame = .init(x: contentView.layoutMargins.left - 2, y: contentView.layoutMargins.top, width: 42, height: 42)
        permissionDrawIconView.frame = permissionIconContainerView.bounds
        permissionIconImageView.frame = permissionIconContainerView.bounds
        
        // Button
        
        permissionButton.sizeToFit()
        permissionButton.frame.origin.x = contentView.frame.width - contentView.layoutMargins.right - permissionButton.frame.width
        
        // Titles
        
        let leftContentLeadingSpace: CGFloat = 13
        let leftContentTrailingSpace: CGFloat = 13
        let leftContentXPosition = contentView.layoutMargins.left + permissionIconContainerView.frame.width + leftContentLeadingSpace
        let leftContentWidth = contentView.frame.width - leftContentXPosition - permissionButton.frame.width - leftContentTrailingSpace - contentView.layoutMargins.right
        
        permissionTitleLabel.layoutDynamicHeight(x: leftContentXPosition, y: contentView.layoutMargins.top, width: leftContentWidth)
        
        permissionDescriptionLabel.layoutDynamicHeight(x: leftContentXPosition, y: permissionTitleLabel.frame.origin.y + permissionTitleLabel.frame.height + 4, width: leftContentWidth)
        
        // Button Vertical Centering
        
        permissionButton.center.y = calculatedHeight / 2
        
        // RTL
        
        if UIApplication.shared.userInterfaceRightToLeft {
            permissionIconContainerView.frame.origin.x = contentView.frame.width - contentView.layoutMargins.right - permissionIconContainerView.frame.width
            permissionButton.frame.origin.x = contentView.layoutMargins.right
            permissionTitleLabel.frame.origin.x = permissionIconContainerView.frame.origin.x - leftContentLeadingSpace - permissionTitleLabel.frame.width
            permissionDescriptionLabel.frame.origin.x = permissionTitleLabel.frame.origin.x
        }
    }
    
    private var calculatedHeight: CGFloat {
        return permissionDescriptionLabel.frame.origin.y + permissionDescriptionLabel.frame.height + contentView.layoutMargins.bottom
    }
    
    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        let superSize = super.sizeThatFits(size)
        layoutSubviews()
        return CGSize.init(width: superSize.width, height: calculatedHeight)
    }
    
    // MARK: - Helpers
    
    func defaultConfigure(for permission: SPPermissions.Permission) {
        
        permissionTitleLabel.text = Text.permission_name(permission.type)
        permissionDescriptionLabel.text = Text.permission_description(permission.type)
        
        permissionButton.permission = permission
        permissionButton.allowTitle = Text.allow_permission_action
        permissionButton.allowedTitle = Text.allowed_permission_action
        permissionButton.allowTitleColor = UIColor.tint
        permissionButton.allowBackgroundColor = UIColor.buttonArea
        permissionButton.allowedTitleColor = UIColor.white
        permissionButton.allowedBackgroundColor = UIColor.tint
        
        permissionDrawIconView.permission = permission
        permissionDrawIconView.tintColor = permissionButton.allowedBackgroundColor
        
        permissionIconImageView.image = nil
        permissionIconImageView.contentMode = .scaleAspectFit
        permissionIconImageView.tintColor = permissionButton.allowedBackgroundColor
    
        layoutSubviews()
    }
    
    func updateInterface(animated: Bool) {
    
        let changes = { [weak self] in
            guard let self = self else { return }
            self.permissionButton.updateInterface()
            self.layoutSubviews()
        }
        
        if animated {
            UIView.animate(withDuration: 0.3, animations: {
                changes()
            })
        } else {
            changes()
        }
    }
}

#endif

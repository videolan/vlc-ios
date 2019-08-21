/*****************************************************************************
 * MovieViewController.swift
 *
 * Copyright © 2019 VLC authors and VideoLAN
 *
 * Authors: Robert Gordon <robwaynegordon@gmail.com>
 *
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

@objc (VLCMovieViewControllerDelegate)
protocol MovieViewControllerDelegate {
}

@objc (VLCMovieViewController)
@objcMembers class MovieViewController: UIView {
    
    // MARK: Instance Variables
    weak var delegate:  VLCMovieViewControllerDelegate?
    
    // MARK: Initializers
    required init(coder: NSCoder) {
        fatalError("init(coder: NSCoder) not implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
}

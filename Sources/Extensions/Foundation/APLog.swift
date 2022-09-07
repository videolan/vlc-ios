/*****************************************************************************
 * APLog.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2021 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Edgar Fouillet <vlc # edgar.fouillet.eu>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

func APLog(_ log: Any) {
    #if DEBUG
    print(log)
    #endif
}

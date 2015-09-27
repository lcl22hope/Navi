//
//  UIImage+Navi.swift
//  Chidori
//
//  Created by NIX on 15/9/27.
//  Copyright © 2015年 nixWork. All rights reserved.
//

import UIKit
import CoreImage

// MARK: - API

extension UIImage {

    func avatarImageWithStyle(avatarStyle: AvatarStyle) -> UIImage {

        var avatarImage: UIImage?

        switch avatarStyle {

        case .Rectangle(let size):
            avatarImage = centerCropWithSize(size)

        case .RoundedRectangle(let size, let cornerRadius, let borderWidth):
            avatarImage = centerCropWithSize(size)?.roundWithCornerRadius(cornerRadius, borderWidth: borderWidth)
        }

        return avatarImage ?? self
    }
}

// MARK: - Resize

extension UIImage {

    func resizeToSize(size: CGSize, withTransform transform: CGAffineTransform, drawTransposed: Bool, interpolationQuality: CGInterpolationQuality) -> UIImage? {

        let newRect = CGRectIntegral(CGRect(origin: CGPointZero, size: size))
        let transposedRect = CGRect(origin: CGPointZero, size: CGSize(width: size.height, height: size.width))

        let bitmapContext = CGBitmapContextCreate(nil, Int(newRect.width), Int(newRect.height), CGImageGetBitsPerComponent(CGImage), 0, CGImageGetColorSpace(CGImage), CGImageGetBitmapInfo(CGImage).rawValue)

        CGContextConcatCTM(bitmapContext, transform)

        CGContextSetInterpolationQuality(bitmapContext, interpolationQuality)

        CGContextDrawImage(bitmapContext, drawTransposed ? transposedRect : newRect, CGImage)

        if let newCGImage = CGBitmapContextCreateImage(bitmapContext) {
            return UIImage(CGImage: newCGImage)
        }

        return nil
    }

    func transformForOrientationWithSize(size: CGSize) -> CGAffineTransform {
        var transform = CGAffineTransformIdentity

        switch imageOrientation {
        case .Down, .DownMirrored:
            transform = CGAffineTransformTranslate(transform, size.width, size.height)
            transform = CGAffineTransformRotate(transform, CGFloat(M_PI))

        case .Left, .LeftMirrored:
            transform = CGAffineTransformTranslate(transform, size.width, 0)
            transform = CGAffineTransformRotate(transform, CGFloat(M_PI_2))

        case .Right, .RightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, size.height)
            transform = CGAffineTransformRotate(transform, CGFloat(-M_PI_2))

        default:
            break
        }

        switch imageOrientation {
        case .UpMirrored, .DownMirrored:
            transform = CGAffineTransformTranslate(transform, size.width, 0)
            transform = CGAffineTransformScale(transform, -1, 1)

        case .LeftMirrored, .RightMirrored:
            transform = CGAffineTransformTranslate(transform, size.height, 0)
            transform = CGAffineTransformScale(transform, -1, 1)

        default:
            break
        }

        return transform
    }

    func resizeToSize(size: CGSize, withInterpolationQuality interpolationQuality: CGInterpolationQuality) -> UIImage? {

        let drawTransposed: Bool

        switch imageOrientation {
        case .Left, .LeftMirrored, .Right, .RightMirrored:
            drawTransposed = true
        default:
            drawTransposed = false
        }

        return resizeToSize(size, withTransform: transformForOrientationWithSize(size), drawTransposed: drawTransposed, interpolationQuality: interpolationQuality)
    }

    func cropWithBounds(bounds: CGRect) -> UIImage? {

        if let newCGImage = CGImageCreateWithImageInRect(CGImage, bounds) {
            return UIImage(CGImage: newCGImage)
        }

        return nil
    }

    func centerCropWithSize(size: CGSize) -> UIImage? {

        let scale = UIScreen.mainScreen().scale
        let size = CGSize(width: size.width * scale, height: size.height * scale)

        let horizontalRatio = size.width / self.size.width
        let verticalRatio = size.height / self.size.height

        let ratio: CGFloat

        let originalX: CGFloat
        let originalY: CGFloat

        if horizontalRatio > verticalRatio {
            ratio = horizontalRatio

            originalX = 0
            originalY = (self.size.height - size.height / ratio) / 2

        } else {
            ratio = verticalRatio

            originalX = (self.size.width - size.width / ratio) / 2
            originalY = 0
        }

        let bounds = CGRect(x: originalX, y: originalY, width: size.width / ratio, height: size.height / ratio)

        return cropWithBounds(bounds)?.resizeToSize(size, withInterpolationQuality: .Default)
    }
}

// MARK: - Round

extension UIImage {

    func roundWithCornerRadius(cornerRadius: CGFloat, borderWidth: CGFloat) -> UIImage? {

        let image = imageWithAlpha()

        let cornerRadius = cornerRadius * UIScreen.mainScreen().scale

        let bitmapContext = CGBitmapContextCreate(nil, Int(image.size.width), Int(image.size.height), CGImageGetBitsPerComponent(image.CGImage), 0, CGImageGetColorSpace(image.CGImage), CGImageGetBitmapInfo(image.CGImage).rawValue)

        let imageRect = CGRect(origin: CGPointZero, size: image.size)

        let scale = UIScreen.mainScreen().scale

        let path = UIBezierPath(roundedRect: CGRectIntegral(CGRectInset(imageRect, borderWidth * scale, borderWidth * scale)), cornerRadius: cornerRadius)

        CGContextAddPath(bitmapContext, path.CGPath)
        CGContextClip(bitmapContext)

        CGContextDrawImage(bitmapContext, imageRect, image.CGImage)

        if let newCGImage = CGBitmapContextCreateImage(bitmapContext) {
            return UIImage(CGImage: newCGImage)
        }

        return nil
    }
}

// MARK: - Alpha

extension UIImage {

    func hasAlpha() -> Bool {
        let alpha = CGImageGetAlphaInfo(CGImage)

        return (
            alpha == .First ||
                alpha == .Last ||
                alpha == .PremultipliedFirst ||
                alpha == .PremultipliedLast
        )
    }

    func imageWithAlpha() -> UIImage {

        if hasAlpha() {
            return self
        }

        let width = CGImageGetWidth(CGImage)
        let height = CGImageGetHeight(CGImage)

        let offscreenContext = CGBitmapContextCreate(nil, width, height, 8, 0, CGImageGetColorSpace(CGImage), CGBitmapInfo(rawValue: CGBitmapInfo.ByteOrderDefault.rawValue | CGImageAlphaInfo.PremultipliedFirst.rawValue).rawValue)
        
        CGContextDrawImage(offscreenContext, CGRect(origin: CGPointZero, size: CGSize(width: width, height: height)), CGImage)
        
        if let alphaCGImage = CGBitmapContextCreateImage(offscreenContext) {
            return UIImage(CGImage: alphaCGImage)
        } else {
            return self
        }
    }
}


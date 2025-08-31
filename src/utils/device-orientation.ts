/**
 * Modern device orientation handling using native APIs
 * Replaces the old gyronorm library with modern browser APIs
 */

import type { DeviceOrientationData } from '../types'

export class DeviceOrientationManager {
  private callback?: (data: DeviceOrientationData) => void
  private isActive = false
  private readonly maxTilt: number

  constructor(maxTilt = 15) {
    this.maxTilt = maxTilt
    this.handleOrientation = this.handleOrientation.bind(this)
  }

  async requestPermission(): Promise<boolean> {
    // For iOS 13+ devices, we need to request permission
    if (
      typeof DeviceOrientationEvent !== 'undefined' &&
      typeof (DeviceOrientationEvent as any).requestPermission === 'function'
    ) {
      try {
        const permission = await (
          DeviceOrientationEvent as any
        ).requestPermission()
        return permission === 'granted'
      } catch (error) {
        console.warn('Device orientation permission denied:', error)
        return false
      }
    }
    return true
  }

  async start(callback: (data: DeviceOrientationData) => void): Promise<void> {
    if (this.isActive) return

    const hasPermission = await this.requestPermission()
    if (!hasPermission) {
      throw new Error('Device orientation permission denied')
    }

    this.callback = callback
    this.isActive = true

    window.addEventListener('deviceorientation', this.handleOrientation, {
      passive: true,
    })
  }

  stop(): void {
    if (!this.isActive) return

    this.isActive = false
    this.callback = undefined
    window.removeEventListener('deviceorientation', this.handleOrientation)
  }

  private handleOrientation(event: DeviceOrientationEvent): void {
    if (!this.callback || !this.isActive) return

    const { alpha, beta, gamma } = event

    // Provide fallback values for null orientations
    const data: DeviceOrientationData = {
      alpha: alpha ?? 0,
      beta: beta ?? 0,
      gamma: gamma ?? 0,
      absolute: event.absolute ?? false,
    }

    this.callback(data)
  }

  // Convert orientation data to normalized mouse-like coordinates
  orientationToMouse(data: DeviceOrientationData): { x: number; y: number } {
    const clamp = (value: number, min: number, max: number) =>
      Math.min(Math.max(value, min), max)

    const normalizedBeta =
      clamp(data.beta, -this.maxTilt, this.maxTilt) / this.maxTilt
    const normalizedGamma =
      clamp(data.gamma, -this.maxTilt, this.maxTilt) / this.maxTilt

    return {
      x: -normalizedGamma, // Invert gamma for natural feel
      y: normalizedBeta,
    }
  }

  // Static version for backward compatibility
  static orientationToMouse(
    data: DeviceOrientationData,
    maxTilt = 15
  ): { x: number; y: number } {
    const clamp = (value: number, min: number, max: number) =>
      Math.min(Math.max(value, min), max)

    const normalizedBeta = clamp(data.beta, -maxTilt, maxTilt) / maxTilt
    const normalizedGamma = clamp(data.gamma, -maxTilt, maxTilt) / maxTilt

    return {
      x: -normalizedGamma, // Invert gamma for natural feel
      y: normalizedBeta,
    }
  }
}

export interface DeviceOrientationData {
  alpha: number
  beta: number
  gamma: number
  absolute: boolean
}

export interface WebGLUniforms {
  resolution: WebGLUniformLocation | null
  mouse: WebGLUniformLocation | null
  time: WebGLUniformLocation | null
  pixelRatio: WebGLUniformLocation | null
  threshold: WebGLUniformLocation | null
}

export interface ImageData {
  original: string
  depth: string
  horizontalThreshold: number
  verticalThreshold: number
}

export interface MousePosition {
  x: number
  y: number
  targetX: number
  targetY: number
}

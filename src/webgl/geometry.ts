/**
 * Modern WebGL geometry classes
 */

export class Rect {
  private static readonly vertices = new Float32Array([
    -1,
    -1, // bottom-left
    1,
    -1, // bottom-right
    -1,
    1, // top-left
    1,
    1, // top-right
  ])

  private buffer: WebGLBuffer

  constructor(gl: WebGLRenderingContext) {
    const buffer = gl.createBuffer()
    if (!buffer) {
      throw new Error('Failed to create vertex buffer')
    }

    this.buffer = buffer
    gl.bindBuffer(gl.ARRAY_BUFFER, buffer)
    gl.bufferData(gl.ARRAY_BUFFER, Rect.vertices, gl.STATIC_DRAW)
  }

  render(gl: WebGLRenderingContext): void {
    gl.bindBuffer(gl.ARRAY_BUFFER, this.buffer)
    gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4)
  }

  dispose(gl: WebGLRenderingContext): void {
    gl.deleteBuffer(this.buffer)
  }
}

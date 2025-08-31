/**
 * Modern WebGL Uniform class with type safety
 */

export class Uniform {
  private location: WebGLUniformLocation | null
  private gl: WebGLRenderingContext
  private suffix: string

  constructor(
    name: string,
    suffix: string,
    program: WebGLProgram,
    gl: WebGLRenderingContext
  ) {
    this.gl = gl
    this.suffix = suffix
    this.location = gl.getUniformLocation(program, name)

    if (!this.location) {
      console.warn(`Uniform "${name}" not found in shader program`)
    }
  }

  set(...values: number[]): void {
    if (!this.location) return

    const methodName = `uniform${this.suffix}` as keyof WebGLRenderingContext
    const method = this.gl[methodName] as Function

    if (typeof method !== 'function') {
      throw new Error(`Invalid uniform method: ${methodName}`)
    }

    method.call(this.gl, this.location, ...values)
  }
}

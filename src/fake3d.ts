/**
 * Modern Fake 3D Effect with WebGL - TypeScript Implementation
 * Completely rewritten with modern patterns, performance optimizations, and type safety
 */

import fragmentShader from './shaders/fragment.glsl'
import vertexShader from './shaders/vertex.glsl'
import { Uniform } from './webgl/uniform'
import { Rect } from './webgl/geometry'
import { DeviceOrientationManager } from './utils/device-orientation'
import {
  createShader,
  createProgram,
  createTexture,
  loadImages,
} from './utils/webgl'
import type { ImageData, MousePosition } from './types'

// Demo configurations
const DEMO_CONFIGS = {
  lady: {
    original: 'img/lady.jpg',
    depth: 'img/lady-map.jpg',
    horizontalThreshold: 35,
    verticalThreshold: 15,
  },
  ball: {
    original: 'img/ball.jpg',
    depth: 'img/ball-map.jpg',
    horizontalThreshold: 15,
    verticalThreshold: 25,
  },
  mount: {
    original: 'img/mount.jpg',
    depth: 'img/mount-map.jpg',
    horizontalThreshold: 15,
    verticalThreshold: 25,
  },
  canyon: {
    original: 'img/canyon.jpg',
    depth: 'img/canyon-map.jpg',
    horizontalThreshold: 35,
    verticalThreshold: 25,
  },
}

export class Fake3DEffect {
  private readonly canvas: HTMLCanvasElement
  private readonly gl: WebGLRenderingContext
  private readonly container: HTMLElement

  // WebGL resources
  private program!: WebGLProgram
  private geometry!: Rect
  private textures: WebGLTexture[] = []

  // Uniforms
  private uniforms = {
    resolution: null as Uniform | null,
    mouse: null as Uniform | null,
    time: null as Uniform | null,
    pixelRatio: null as Uniform | null,
    threshold: null as Uniform | null,
  }

  // State
  private readonly mouse: MousePosition = { x: 0, y: 0, targetX: 0, targetY: 0 }
  private imageData: ImageData
  private imageAspect = 1
  private startTime = performance.now()
  private animationId = 0
  private isDestroyed = false
  private currentDemo = 'lady'

  // Device orientation
  private orientationManager?: DeviceOrientationManager

  // Performance optimizations
  private readonly devicePixelRatio = Math.min(window.devicePixelRatio || 1, 2)
  private dimensions = { width: 0, height: 0, halfX: 0, halfY: 0 }

  constructor(containerId: string) {
    const container = document.getElementById(containerId)
    if (!container) {
      throw new Error(`Container element with id "${containerId}" not found`)
    }

    this.container = container
    this.canvas = document.createElement('canvas')
    this.container.appendChild(this.canvas)

    // Get WebGL context with optimized settings
    const gl = this.canvas.getContext('webgl', {
      antialias: false,
      alpha: false,
      depth: false,
      stencil: false,
      powerPreference: 'high-performance',
      failIfMajorPerformanceCaveat: false,
    })

    if (!gl) {
      throw new Error('WebGL not supported')
    }

    this.gl = gl

    // Initialize with default demo configuration
    this.imageData = DEMO_CONFIGS.lady

    // Bind methods to avoid context issues
    this.render = this.render.bind(this)
    this.handleResize = this.handleResize.bind(this)
    this.handleMouseMove = this.handleMouseMove.bind(this)

    this.init()
  }

  private async init(): Promise<void> {
    try {
      await this.createScene()
      await this.loadTextures()
      this.handleResize()
      this.setupEventListeners()
      this.setupDeviceOrientation()
      this.startRenderLoop()
    } catch (error) {
      console.error('Failed to initialize Fake3D effect:', error)
      throw error
    }
  }

  private async createScene(): Promise<void> {
    // Create shaders
    const vertShader = createShader(
      this.gl,
      this.gl.VERTEX_SHADER,
      vertexShader
    )
    const fragShader = createShader(
      this.gl,
      this.gl.FRAGMENT_SHADER,
      fragmentShader
    )

    // Create program
    this.program = createProgram(this.gl, vertShader, fragShader)
    this.gl.useProgram(this.program)

    // Create uniforms
    this.uniforms.resolution = new Uniform(
      'resolution',
      '4f',
      this.program,
      this.gl
    )
    this.uniforms.mouse = new Uniform('mouse', '2f', this.program, this.gl)
    this.uniforms.time = new Uniform('time', '1f', this.program, this.gl)
    this.uniforms.pixelRatio = new Uniform(
      'pixelRatio',
      '1f',
      this.program,
      this.gl
    )
    this.uniforms.threshold = new Uniform(
      'threshold',
      '2f',
      this.program,
      this.gl
    )

    // Create geometry
    this.geometry = new Rect(this.gl)

    // Setup vertex attributes
    const positionLocation = this.gl.getAttribLocation(
      this.program,
      'a_position'
    )
    this.gl.enableVertexAttribArray(positionLocation)
    this.gl.vertexAttribPointer(positionLocation, 2, this.gl.FLOAT, false, 0, 0)

    // Clean up shaders (they're now part of the program)
    this.gl.deleteShader(vertShader)
    this.gl.deleteShader(fragShader)
  }

  private async loadTextures(): Promise<void> {
    const imageUrls = [this.imageData.original, this.imageData.depth]
    const images = await loadImages(imageUrls)

    // Calculate aspect ratio from the first image
    this.imageAspect = images[0].naturalHeight / images[0].naturalWidth

    // Create textures
    this.textures = images.map(image => createTexture(this.gl, image))

    // Set up texture uniforms
    const image0Location = this.gl.getUniformLocation(this.program, 'image0')
    const image1Location = this.gl.getUniformLocation(this.program, 'image1')

    this.gl.uniform1i(image0Location, 0)
    this.gl.uniform1i(image1Location, 1)

    // Bind textures to texture units
    this.gl.activeTexture(this.gl.TEXTURE0)
    this.gl.bindTexture(this.gl.TEXTURE_2D, this.textures[0])
    this.gl.activeTexture(this.gl.TEXTURE1)
    this.gl.bindTexture(this.gl.TEXTURE_2D, this.textures[1])
  }

  private setupEventListeners(): void {
    window.addEventListener('resize', this.handleResize, { passive: true })
    document.addEventListener('mousemove', this.handleMouseMove, {
      passive: true,
    })

    // Setup demo switching buttons
    const demoButtons = document.querySelectorAll('[data-demo]')
    demoButtons.forEach(button => {
      button.addEventListener('click', e => {
        e.preventDefault()
        e.stopPropagation()
        const target = e.target as HTMLElement
        const demo = target.getAttribute('data-demo')
        if (demo && demo in DEMO_CONFIGS) {
          this.switchDemo(demo as keyof typeof DEMO_CONFIGS)
        }
      })
    })
  }

  private async setupDeviceOrientation(): Promise<void> {
    try {
      this.orientationManager = new DeviceOrientationManager(15)
      await this.orientationManager.start(data => {
        const mouseCoords = this.orientationManager!.orientationToMouse(data)
        this.mouse.targetX = mouseCoords.x
        this.mouse.targetY = mouseCoords.y
      })
    } catch (error) {
      console.log('Device orientation not supported or permission denied')
    }
  }

  private handleResize(): void {
    const rect = this.container.getBoundingClientRect()
    this.dimensions.width = rect.width
    this.dimensions.height = rect.height
    this.dimensions.halfX = this.dimensions.width / 2
    this.dimensions.halfY = this.dimensions.height / 2

    // Set canvas size with device pixel ratio
    this.canvas.width = this.dimensions.width * this.devicePixelRatio
    this.canvas.height = this.dimensions.height * this.devicePixelRatio
    this.canvas.style.width = `${this.dimensions.width}px`
    this.canvas.style.height = `${this.dimensions.height}px`

    // Calculate aspect ratio adjustments
    const canvasAspect = this.dimensions.height / this.dimensions.width
    let scaleX = 1
    let scaleY = 1

    if (canvasAspect < this.imageAspect) {
      scaleX = 1
      scaleY = canvasAspect / this.imageAspect
    } else {
      scaleX =
        (this.dimensions.width / this.dimensions.height) * this.imageAspect
      scaleY = 1
    }

    // Update uniforms
    this.uniforms.resolution?.set(
      this.dimensions.width,
      this.dimensions.height,
      scaleX,
      scaleY
    )
    this.uniforms.pixelRatio?.set(1 / this.devicePixelRatio)
    this.uniforms.threshold?.set(
      this.imageData.horizontalThreshold,
      this.imageData.verticalThreshold
    )

    // Set viewport
    this.gl.viewport(0, 0, this.canvas.width, this.canvas.height)
  }

  private handleMouseMove(event: MouseEvent): void {
    this.mouse.targetX =
      (this.dimensions.halfX - event.clientX) / this.dimensions.halfX
    this.mouse.targetY =
      (this.dimensions.halfY - event.clientY) / this.dimensions.halfY
  }

  private startRenderLoop(): void {
    if (this.isDestroyed) return
    this.render()
  }

  private render(): void {
    if (this.isDestroyed) return

    // Update time
    const currentTime = (performance.now() - this.startTime) / 1000
    this.uniforms.time?.set(currentTime)

    // Smooth mouse movement with easing
    const ease = 0.05
    this.mouse.x += (this.mouse.targetX - this.mouse.x) * ease
    this.mouse.y += (this.mouse.targetY - this.mouse.y) * ease

    this.uniforms.mouse?.set(this.mouse.x, this.mouse.y)

    // Render
    this.geometry.render(this.gl)

    // Schedule next frame
    this.animationId = requestAnimationFrame(this.render)
  }

  // Demo switching
  private async switchDemo(demo: keyof typeof DEMO_CONFIGS): Promise<void> {
    if (demo === this.currentDemo) return

    this.currentDemo = demo
    this.imageData = DEMO_CONFIGS[demo]

    // Update button states
    document.querySelectorAll('[data-demo]').forEach(button => {
      button.classList.remove('frame__demo--current')
    })
    document
      .querySelector(`[data-demo="${demo}"]`)
      ?.classList.add('frame__demo--current')

    // Clean up old textures
    this.textures.forEach(texture => this.gl.deleteTexture(texture))
    this.textures = []

    // Load new textures
    await this.loadTextures()

    // Update container attributes for consistency
    this.container.setAttribute('data-imageOriginal', this.imageData.original)
    this.container.setAttribute('data-imageDepth', this.imageData.depth)
    this.container.setAttribute(
      'data-horizontalThreshold',
      this.imageData.horizontalThreshold.toString()
    )
    this.container.setAttribute(
      'data-verticalThreshold',
      this.imageData.verticalThreshold.toString()
    )

    // Update thresholds
    this.uniforms.threshold?.set(
      this.imageData.horizontalThreshold,
      this.imageData.verticalThreshold
    )
  }

  // Public API
  public destroy(): void {
    if (this.isDestroyed) return

    this.isDestroyed = true

    // Cancel animation
    if (this.animationId) {
      cancelAnimationFrame(this.animationId)
    }

    // Clean up device orientation
    this.orientationManager?.stop()

    // Remove event listeners
    window.removeEventListener('resize', this.handleResize)
    document.removeEventListener('mousemove', this.handleMouseMove)

    // Clean up WebGL resources
    this.textures.forEach(texture => this.gl.deleteTexture(texture))
    this.geometry.dispose(this.gl)
    this.gl.deleteProgram(this.program)

    // Remove canvas
    this.canvas.remove()
  }

  public updateThresholds(horizontal: number, vertical: number): void {
    this.imageData.horizontalThreshold = horizontal
    this.imageData.verticalThreshold = vertical
    this.uniforms.threshold?.set(horizontal, vertical)
  }
}

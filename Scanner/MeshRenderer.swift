//
//	This file is a Swift port of the Structure SDK sample app "Scanner".
//	Copyright © 2016 Occipital, Inc. All rights reserved.
//	http://structure.io
//
//  MeshRenderer.swift
//
//  Ported by Christopher Worley on 8/20/16.
//

let MAX_MESHES: Int = 30

class MeshRenderer : NSObject {
	
	enum RenderingMode: Int {
		
        case XRay = 0
        case PerVertexColor
        case Textured
        case LightedGray
    }

    struct PrivateData {
		
        var lightedGrayShader: LightedGrayShader?
        var perVertexColorShader: PerVertexColorShader?
        var xRayShader: XrayShader?
        var yCbCrTextureShader: YCbCrTextureShader?
		
        var numUploadedMeshes: Int = 0
		var numTriangleIndices = [Int](count: MAX_MESHES, repeatedValue: 0)
        var numLinesIndices = [Int](count: MAX_MESHES, repeatedValue: 0)
		
        var hasPerVertexColor: Bool = false
        var hasPerVertexNormals: Bool = false
        var hasPerVertexUV: Bool = false
        var hasTexture: Bool = false
		
        // Vertex buffer objects.
        var vertexVbo = [GLuint](count: MAX_MESHES, repeatedValue: 0)
        var normalsVbo = [GLuint](count: MAX_MESHES, repeatedValue: 0)
        var colorsVbo = [GLuint](count: MAX_MESHES, repeatedValue: 0)
        var texcoordsVbo = [GLuint](count: MAX_MESHES, repeatedValue: 0)
        var facesVbo = [GLuint](count: MAX_MESHES, repeatedValue: 0)
        var linesVbo = [GLuint](count: MAX_MESHES, repeatedValue: 0)
		
        // OpenGL Texture reference for y and chroma images.
        var lumaTexture: CVOpenGLESTexture? = nil
        var chromaTexture: CVOpenGLESTexture? = nil
		
        // OpenGL Texture cache for the color texture.
        var textureCache: CVOpenGLESTextureCache? = nil
		
        // Texture unit to use for texture binding/rendering.
        var textureUnit: GLenum = GLenum(GL_TEXTURE3)
		
        // Current render mode.
        var currentRenderingMode: RenderingMode = .LightedGray
		
		internal init() {
			
			lightedGrayShader = LightedGrayShader()
			perVertexColorShader = PerVertexColorShader()
			xRayShader = XrayShader()
			yCbCrTextureShader = YCbCrTextureShader()
		}
    }
	
	var d: PrivateData?
    
	override init() {

		self.d = PrivateData.init()

	}
  
   func initializeGL(defaultTextureUnit: GLenum = GLenum(GL_TEXTURE3)) {
		
        d!.textureUnit = defaultTextureUnit
        glGenBuffers( GLsizei(MAX_MESHES), &d!.vertexVbo)
        glGenBuffers( GLsizei(MAX_MESHES), &d!.normalsVbo)
        glGenBuffers( GLsizei(MAX_MESHES), &d!.colorsVbo)
        glGenBuffers( GLsizei(MAX_MESHES), &d!.texcoordsVbo)
        glGenBuffers( GLsizei(MAX_MESHES), &d!.facesVbo)
        glGenBuffers( GLsizei(MAX_MESHES), &d!.linesVbo)
    }
    
  func releaseGLTextures() {
		
        if (d!.lumaTexture != nil) {

            d!.lumaTexture = nil
        }
		
        if (d!.chromaTexture != nil) {

            d!.chromaTexture = nil
        }
		
        if (d!.textureCache != nil) {

            d!.textureCache = nil
        }
    }
    
  func releaseGLBuffers() {
		
        for meshIndex in 0..<d!.numUploadedMeshes {
			
            glBindBuffer( GLenum(GL_ARRAY_BUFFER), d!.vertexVbo[meshIndex])
            glBufferData( GLenum(GL_ARRAY_BUFFER), 0, nil, GLenum(GL_STATIC_DRAW))
			
            glBindBuffer( GLenum(GL_ARRAY_BUFFER), d!.normalsVbo[meshIndex])
            glBufferData( GLenum(GL_ARRAY_BUFFER), 0, nil, GLenum(GL_STATIC_DRAW))
			
            glBindBuffer( GLenum(GL_ARRAY_BUFFER), d!.colorsVbo[meshIndex])
            glBufferData( GLenum(GL_ARRAY_BUFFER), 0, nil, GLenum(GL_STATIC_DRAW))
			
            glBindBuffer( GLenum(GL_ARRAY_BUFFER), d!.texcoordsVbo[meshIndex])
            glBufferData( GLenum(GL_ARRAY_BUFFER), 0, nil, GLenum(GL_STATIC_DRAW))
			
            glBindBuffer( GLenum(GL_ELEMENT_ARRAY_BUFFER), d!.facesVbo[meshIndex])
            glBufferData( GLenum(GL_ELEMENT_ARRAY_BUFFER), 0, nil, GLenum(GL_STATIC_DRAW))
			
            glBindBuffer( GLenum(GL_ELEMENT_ARRAY_BUFFER), d!.linesVbo[meshIndex])
            glBufferData( GLenum(GL_ELEMENT_ARRAY_BUFFER), 0, nil, GLenum(GL_STATIC_DRAW))
        }
    }
	
	deinit {
		
		MeshRendererDestructor(self.d!)
		
		self.d = nil
	}
	
    func MeshRendererDestructor(d: PrivateData) {
		
        if d.vertexVbo[0] != 0 {
            glDeleteBuffers( GLsizei(MAX_MESHES), d.vertexVbo)
        }
        if d.normalsVbo[0] != 0 {
            glDeleteBuffers( GLsizei(MAX_MESHES), d.normalsVbo)
        }
        if d.colorsVbo[0] != 0 {
            glDeleteBuffers( GLsizei(MAX_MESHES), d.colorsVbo)
        }
        if d.texcoordsVbo[0] != 0 {
            glDeleteBuffers( GLsizei(MAX_MESHES), d.texcoordsVbo)
        }
        if d.facesVbo[0] != 0 {
            glDeleteBuffers( GLsizei(MAX_MESHES), d.facesVbo)
        }
        if d.linesVbo[0] != 0 {
            glDeleteBuffers( GLsizei(MAX_MESHES), d.linesVbo)
        }
		
        releaseGLTextures()
		
		self.d!.lightedGrayShader = nil
		self.d!.perVertexColorShader = nil
		self.d!.xRayShader = nil
		self.d!.yCbCrTextureShader = nil
		self.d!.numUploadedMeshes = 0
    }
	
   func clear() {
    
        if d!.currentRenderingMode == RenderingMode.PerVertexColor || d!.currentRenderingMode == RenderingMode.Textured {
            glClearColor(0.9, 0.9, 0.9, 1)
        }
        else {
            glClearColor(0.1, 0.1, 0.1, 1)
        } 
 
        glClearDepthf(1)
		
        glClear( GLenum(GL_COLOR_BUFFER_BIT) | GLenum(GL_DEPTH_BUFFER_BIT))
    }
    
   func setRenderingMode(mode: RenderingMode) {
        d!.currentRenderingMode = mode
    }
    
   func getRenderingMode() -> RenderingMode {
        return d!.currentRenderingMode
    }
 
    
    func uploadMesh(mesh: STMesh) {

        let numUploads: Int = min(Int(mesh.numberOfMeshes()), Int(MAX_MESHES))
        d!.numUploadedMeshes = min(Int(mesh.numberOfMeshes()), Int(MAX_MESHES))
		
        d!.hasPerVertexColor = mesh.hasPerVertexColors()
        d!.hasPerVertexNormals = mesh.hasPerVertexNormals()
        d!.hasPerVertexUV = mesh.hasPerVertexUVTextureCoords()
        d!.hasTexture = (mesh.meshYCbCrTexture() != nil)
        
        if d!.hasTexture {
            uploadTexture(mesh.meshYCbCrTexture as! CVPixelBufferRef)
        }
		
        for meshIndex in 0..<numUploads {
			
            let numVertices: Int = Int(mesh.numberOfMeshVertices(Int32(meshIndex)))
			
            glBindBuffer( GLenum(GL_ARRAY_BUFFER), d!.vertexVbo[meshIndex])
            glBufferData( GLenum(GL_ARRAY_BUFFER), numVertices * sizeof(GLKVector3), mesh.meshVertices(Int32(meshIndex)), GLenum(GL_STATIC_DRAW))
			
            if d!.hasPerVertexNormals {
				
                glBindBuffer( GLenum(GL_ARRAY_BUFFER), d!.normalsVbo[meshIndex])
                glBufferData( GLenum(GL_ARRAY_BUFFER), numVertices * sizeof(GLKVector3), mesh.meshPerVertexNormals(Int32(meshIndex)), GLenum(GL_STATIC_DRAW))
            }
			
            if d!.hasPerVertexColor {
				
                glBindBuffer( GLenum(GL_ARRAY_BUFFER), d!.colorsVbo[meshIndex])
                glBufferData( GLenum(GL_ARRAY_BUFFER), numVertices * sizeof(GLKVector3), mesh.meshPerVertexColors(Int32(meshIndex)), GLenum(GL_STATIC_DRAW))
            }
			
            if d!.hasPerVertexUV {
				
                glBindBuffer( GLenum(GL_ARRAY_BUFFER), d!.texcoordsVbo[meshIndex])
                glBufferData( GLenum(GL_ARRAY_BUFFER), numVertices * sizeof(GLKVector2), mesh.meshPerVertexUVTextureCoords(Int32(meshIndex)), GLenum(GL_STATIC_DRAW))
            }
			
            glBindBuffer( GLenum(GL_ELEMENT_ARRAY_BUFFER), d!.facesVbo[meshIndex])
            glBufferData( GLenum(GL_ELEMENT_ARRAY_BUFFER), Int(mesh.numberOfMeshFaces(Int32(meshIndex))) * sizeof(UInt16) * 3, mesh.meshFaces(Int32(meshIndex)), GLenum(GL_STATIC_DRAW))
            
            glBindBuffer( GLenum(GL_ELEMENT_ARRAY_BUFFER), d!.linesVbo[meshIndex])
            glBufferData( GLenum(GL_ELEMENT_ARRAY_BUFFER), Int(mesh.numberOfMeshLines(Int32(meshIndex))) * sizeof(UInt16) * 2, mesh.meshLines(Int32(meshIndex)), GLenum(GL_STATIC_DRAW))
			
            glBindBuffer( GLenum(GL_ELEMENT_ARRAY_BUFFER), 0)
            glBindBuffer( GLenum(GL_ARRAY_BUFFER), 0)
			
            d!.numTriangleIndices[meshIndex] = Int(mesh.numberOfMeshFaces(Int32(meshIndex)) * 3)
            d!.numLinesIndices[meshIndex] = Int(mesh.numberOfMeshLines(Int32(meshIndex)) * 2)
        }
    }
    
    func uploadTexture(pixelBuffer: CVImageBuffer) {
		
        let width = Int(CVPixelBufferGetWidth(pixelBuffer))
        let height = Int(CVPixelBufferGetHeight(pixelBuffer))
		
        let context: EAGLContext? = EAGLContext.currentContext()
        assert(context != nil)
		
        releaseGLTextures()
		
        if d!.textureCache == nil {
			
            let texError = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, nil, context!, nil, &d!.textureCache)
            if texError != kCVReturnSuccess {
                NSLog("Error at CVOpenGLESTextureCacheCreate \(texError)")
            }
        }

        // Allow the texture cache to do internal cleanup.
        CVOpenGLESTextureCacheFlush(d!.textureCache!, 0)

        let pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)
        assert(pixelFormat == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
		
        // Activate the default texture unit.
        glActiveTexture(d!.textureUnit)

        // Create a new Y texture from the video texture cache.
        var err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, d!.textureCache!, pixelBuffer, nil, GLenum(GL_TEXTURE_2D), GL_RED_EXT, GLsizei(width), GLsizei(height), GLenum(GL_RED_EXT), GLenum(GL_UNSIGNED_BYTE), 0, &d!.lumaTexture)

        if err != kCVReturnSuccess {
            NSLog("Error with CVOpenGLESTextureCacheCreateTextureFromImage: \(err)")
            return
        }

        // Set rendering properties for the new texture.
        glBindTexture(CVOpenGLESTextureGetTarget(d!.lumaTexture!), CVOpenGLESTextureGetName(d!.lumaTexture!))
        glTexParameterf( GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GLfloat(GL_CLAMP_TO_EDGE))
        glTexParameterf( GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GLfloat(GL_CLAMP_TO_EDGE))
		
        // Activate the next texture unit for CbCr.
        glActiveTexture(d!.textureUnit + 1)

        // Create a new CbCr texture from the video texture cache.
        err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, d!.textureCache!, pixelBuffer, nil, GLenum(GL_TEXTURE_2D), GL_RG_EXT, Int32(width) / 2, Int32(height) / 2, GLenum(GL_RG_EXT), GLenum(GL_UNSIGNED_BYTE), 1, &d!.chromaTexture)
		
        if err != kCVReturnSuccess {
            NSLog("Error with CVOpenGLESTextureCacheCreateTextureFromImage: \(err)")
            return
        }

        glBindTexture(CVOpenGLESTextureGetTarget(d!.chromaTexture!), CVOpenGLESTextureGetName(d!.chromaTexture!))
        glTexParameterf( GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GLfloat(GL_CLAMP_TO_EDGE))
        glTexParameterf( GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GLfloat(GL_CLAMP_TO_EDGE))
        glBindTexture( GLenum(GL_TEXTURE_2D), 0)
    }
    
    func enableVertexBuffer(meshIndex : Int) {
		
        glBindBuffer( GLenum(GL_ARRAY_BUFFER), d!.vertexVbo[meshIndex])
        glEnableVertexAttribArray(CustomShader.Attrib.Vertex.rawValue)
        glVertexAttribPointer(CustomShader.Attrib.Vertex.rawValue, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, nil)
    }
    
    func disableVertexBuffer(meshIndex : Int) {
		
        glBindBuffer( GLenum(GL_ARRAY_BUFFER), d!.vertexVbo[meshIndex])
        glDisableVertexAttribArray(CustomShader.Attrib.Vertex.rawValue)
    }
    
    func enableNormalBuffer (meshIndex : Int) {
		
        glBindBuffer( GLenum(GL_ARRAY_BUFFER), d!.normalsVbo[meshIndex])
        glEnableVertexAttribArray(CustomShader.Attrib.Normal.rawValue)
        glVertexAttribPointer(CustomShader.Attrib.Normal.rawValue, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, nil)
    }
    
    func disableNormalBuffer(meshIndex : Int) {
		
        glBindBuffer( GLenum(GL_ARRAY_BUFFER), d!.normalsVbo[meshIndex])
        glDisableVertexAttribArray(CustomShader.Attrib.Normal.rawValue)
    }
    
    func enableVertexColorBuffer (meshIndex : Int) {
		
        glBindBuffer( GLenum(GL_ARRAY_BUFFER), d!.colorsVbo[meshIndex])
        glEnableVertexAttribArray(CustomShader.Attrib.Color.rawValue)
        glVertexAttribPointer(CustomShader.Attrib.Color.rawValue, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, nil)
    }
    
    func disableVertexColorBuffer(meshIndex : Int) {
		
        glBindBuffer( GLenum(GL_ARRAY_BUFFER), d!.colorsVbo[meshIndex])
        glDisableVertexAttribArray(CustomShader.Attrib.Color.rawValue)
    }
    
    func enableVertexTexcoordsBuffer (meshIndex : Int) {
		
        glBindBuffer( GLenum(GL_ARRAY_BUFFER), d!.texcoordsVbo[meshIndex])
        glEnableVertexAttribArray(CustomShader.Attrib.TextCoord.rawValue)
        glVertexAttribPointer(CustomShader.Attrib.TextCoord.rawValue, 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, nil)
    }
    
    func disableVertexTexcoordBuffer(meshIndex: Int) {
		
        glBindBuffer( GLenum(GL_ARRAY_BUFFER), d!.texcoordsVbo[meshIndex])
        glDisableVertexAttribArray(CustomShader.Attrib.TextCoord.rawValue)
    }
    
    func enableLinesElementBuffer (meshIndex: Int) {
		
        glBindBuffer( GLenum(GL_ELEMENT_ARRAY_BUFFER), d!.linesVbo[meshIndex])
        glLineWidth(1.0)
    }
    
    func enableTrianglesElementBuffer (meshIndex: Int)
    {
        glBindBuffer( GLenum(GL_ELEMENT_ARRAY_BUFFER), d!.facesVbo[meshIndex])
    }
	
    func renderPartialMesh (meshIndex: Int)
    {
		//nothing uploaded. return test
        if d!.numTriangleIndices[meshIndex] <= 0 {
            return
        }
		
        switch d!.currentRenderingMode {
			
        case RenderingMode.XRay:
			
            enableLinesElementBuffer(meshIndex)
            enableVertexBuffer(meshIndex)
            enableNormalBuffer(meshIndex)
            glDrawElements( GLenum(GL_LINES), GLsizei(d!.numLinesIndices[meshIndex]), GLenum(GL_UNSIGNED_SHORT), nil)
            disableNormalBuffer(meshIndex)
            disableVertexBuffer(meshIndex)
            
        case RenderingMode.LightedGray:
			
            enableTrianglesElementBuffer(meshIndex)
            enableVertexBuffer(meshIndex)
            enableNormalBuffer(meshIndex)
            glDrawElements( GLenum(GL_TRIANGLES), GLsizei(d!.numTriangleIndices[meshIndex]), GLenum(GL_UNSIGNED_SHORT), nil)
            disableNormalBuffer(meshIndex)
            disableVertexBuffer(meshIndex)
            
        case RenderingMode.PerVertexColor:
			
            enableTrianglesElementBuffer(meshIndex)
            enableVertexBuffer(meshIndex)
            enableNormalBuffer(meshIndex)
            enableVertexColorBuffer(meshIndex)
            glDrawElements( GLenum(GL_TRIANGLES), GLsizei(d!.numTriangleIndices[meshIndex]), GLenum(GL_UNSIGNED_SHORT), nil)
            disableVertexColorBuffer(meshIndex)
            disableNormalBuffer(meshIndex)
            disableVertexBuffer(meshIndex)
            
        case RenderingMode.Textured:
			
            enableTrianglesElementBuffer(meshIndex)
            enableVertexBuffer(meshIndex)
            enableVertexTexcoordsBuffer(meshIndex)
            glDrawElements( GLenum(GL_TRIANGLES), GLsizei(d!.numTriangleIndices[meshIndex]), GLenum(GL_UNSIGNED_SHORT), nil)
            disableVertexTexcoordBuffer(meshIndex)
            disableVertexBuffer(meshIndex)
 
        }
        
        glBindBuffer( GLenum(GL_ELEMENT_ARRAY_BUFFER), 0)
        glBindBuffer( GLenum(GL_ARRAY_BUFFER), 0)
    }
    
 func render(projectionMatrix: UnsafePointer<GLfloat>, modelViewMatrix: UnsafePointer<GLfloat>) {

        if d!.currentRenderingMode == RenderingMode.PerVertexColor && !d!.hasPerVertexColor && d!.hasTexture && d!.hasPerVertexUV {
			
            NSLog("Warning: The mesh has no per-vertex colors, but a texture, switching the rendering mode to Textured")
            d!.currentRenderingMode = RenderingMode.Textured
        }
        else if d!.currentRenderingMode == RenderingMode.Textured && (!d!.hasTexture || !d!.hasPerVertexUV) && d!.hasPerVertexColor {
            NSLog("Warning: The mesh has no texture, but per-vertex colors, switching the rendering mode to PerVertexColor")
            d!.currentRenderingMode = RenderingMode.PerVertexColor
        }

        switch d!.currentRenderingMode {
			
        case RenderingMode.XRay:
            d!.xRayShader!.enable()
            d!.xRayShader!.prepareRendering(projectionMatrix, modelView: modelViewMatrix)
			
        case RenderingMode.LightedGray:
            d!.lightedGrayShader!.enable()
            d!.lightedGrayShader!.prepareRendering(projectionMatrix, modelView: modelViewMatrix)
			
        case RenderingMode.PerVertexColor:
            if !d!.hasPerVertexColor {
                NSLog("Warning: the mesh has no colors, skipping rendering.")
                return
            }
			
            d!.perVertexColorShader!.enable()
            d!.perVertexColorShader!.prepareRendering(projectionMatrix, modelView: modelViewMatrix)
			
        case RenderingMode.Textured:
            if !d!.hasTexture || d!.lumaTexture == nil || d!.chromaTexture == nil {
                NSLog("Warning: null textures, skipping rendering.")
                return
            }
			
            glActiveTexture(d!.textureUnit)
            glBindTexture(CVOpenGLESTextureGetTarget(d!.lumaTexture!), CVOpenGLESTextureGetName(d!.lumaTexture!))
			
            glActiveTexture(d!.textureUnit + 1)
            glBindTexture(CVOpenGLESTextureGetTarget(d!.chromaTexture!), CVOpenGLESTextureGetName(d!.chromaTexture!))
			
            d!.yCbCrTextureShader!.enable()
            d!.yCbCrTextureShader!.prepareRendering(projectionMatrix, modelView: modelViewMatrix, textureUnit: GLint(d!.textureUnit))

        }
        
        // Keep previous GL_DEPTH_TEST state
        let wasDepthTestEnabled: GLboolean = glIsEnabled( GLenum(GL_DEPTH_TEST))
        glEnable( GLenum(GL_DEPTH_TEST))
		
        for i in 0..<d!.numUploadedMeshes {
            renderPartialMesh(i)
        }
		
        if wasDepthTestEnabled == GLboolean(GL_FALSE) {
            glDisable( GLenum(GL_DEPTH_TEST))
        }
    }
}

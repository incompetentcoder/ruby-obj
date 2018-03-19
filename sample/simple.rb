#
# For more samples, visit https://github.com/vaiorabbit/ruby-opengl/tree/master/sample .
#
# Ref.: /glfw-3.0.1/examples/simple.c
#
require 'pry'
require 'opengl'
require 'glfw'
require 'glu'
load '../ruby-obj.rb'


OpenGL.load_lib()
GLFW.load_lib()
GLU.load_lib()

include OpenGL
include GLFW
include GLU

def rotatey(v,ang)
  ang = ang*0.01745
  sina=Math::sin(ang)
  cosa=Math::cos(ang)
  return Numo::SFloat[v[0]*cosa+v[2]*sina,v[1],-v[0]*sina+v[2]*cosa]
end

def rotatex(v,ang)
  ang = ang*0.01745
#  sina=Math::sin(ang)
#  cosa=Math::cos(ang)
#  return Numo::SFloat[v[0],v[1]*cosa-v[2]*sina,v[1]*sina+v[2]*cosa]
  return Numo::SFloat[v[0],v[1]+ang,v[2]]
end

messages=["SPACE to start pry console","LEFT to rotate left","RIGHT to rotate right","UP to rotate up","DOWN to rotate down","W to move forward","S to move backard","A to strafe left","D to strafe right","ENTER to reset position"]

# Press ESC to exit.
key_callback = GLFW::create_callback(:GLFWkeyfun) do |window_handle, key, scancode, action, mods|
  if key == GLFW_KEY_ESCAPE && (action == GLFW_PRESS || action == GLFW_REPEAT)
    glfwSetWindowShouldClose(window_handle, 1)
  end
  if key == GLFW_KEY_SPACE && action == GLFW_PRESS
    binding.pry
  end
  if key == GLFW_KEY_LEFT && (action == GLFW_PRESS || action == GLFW_REPEAT)
    $dir = norm(rotatey($dir,2))
  end
  if key == GLFW_KEY_RIGHT && (action == GLFW_PRESS || action == GLFW_REPEAT)
    $dir = norm(rotatey($dir,-2))
  end
  if key == GLFW_KEY_UP && (action == GLFW_PRESS || action == GLFW_REPEAT)
    $dir = norm(rotatex($dir,2))
  end
  if key == GLFW_KEY_DOWN && (action == GLFW_PRESS || action == GLFW_REPEAT)
    $dir = norm(rotatex($dir,-2))
  end
  if key == GLFW_KEY_W && (action == GLFW_PRESS || action == GLFW_REPEAT)
    $pos = $pos + $dir
  end
  if key == GLFW_KEY_S && (action == GLFW_PRESS || action == GLFW_REPEAT)
    $pos = $pos - $dir
  end
  if key == GLFW_KEY_A && (action == GLFW_PRESS || action == GLFW_REPEAT)
    $pos = $pos + norm(rotatey($dir,90))*$step
  end
  if key == GLFW_KEY_D && (action == GLFW_PRESS || action == GLFW_REPEAT)
    $pos = $pos + norm(rotatey($dir,-90))*$step
  end
  if key == GLFW_KEY_ENTER && action == GLFW_PRESS
    $pos = Numo::SFloat[0,4,10]
    $dir = Numo::SFloat[0,0,-1]
  end
  pp $dir
end

mydraw = Proc.new {|x,name,verts,indices|
      if x.faces
#        glLoadIdentity()
#        glTranslatef(*$trans)
#        glRotatef(*$rot)
        mat = (x.mat && x.mat.Kd) ? x.mat.Kd : x.parent.materials.values[0].Kd
        d = (x.mat && x.mat.d) ? x.mat.d : 1
        matkd = ((x.mat && x.mat.Kd) ? x.mat : x.parent.materials[0]).Kd
        matka = ((x.mat && x.mat.Ka) ? x.mat : x.parent.materials[0]).Ka
        matks = ((x.mat && x.mat.Ks) ? x.mat : x.parent.materials[0]).Ks
        glMaterialfv(GL_FRONT_AND_BACK,GL_AMBIENT,[*matka,d].pack('F*'))
        glMaterialfv(GL_FRONT_AND_BACK,GL_DIFFUSE,[*matkd,d].pack('F*'))
        glMaterialfv(GL_FRONT_AND_BACK,GL_SPECULAR,[*matks,d].pack('F*'))
        if verts
          glVertexPointer(3,GL_FLOAT,0,verts[name])
          glDrawElements(GL_TRIANGLES,x.faces.size,GL_UNSIGNED_INT,indices[name][x.name])
        else
          glBegin(GL_TRIANGLES) 
          x.faces.shape[0].times do |y|
            glVertex3f(x.parent.v[x.faces[y,0],0],x.parent.v[x.faces[y,0],1],x.parent.v[x.faces[y,0],2])
            glVertex3f(x.parent.v[x.faces[y,1],0],x.parent.v[x.faces[y,1],1],x.parent.v[x.faces[y,1],2])
            glVertex3f(x.parent.v[x.faces[y,2],0],x.parent.v[x.faces[y,2],1],x.parent.v[x.faces[y,2],2])
          end
          glEnd()
        end
      end
}

if __FILE__ == $0
#  $pos=Numo::SFloat[5,10,15]
#  $rot=[0,0,1,0]
  messages.each {|x| pp x}
  $step=Numo::SFloat[1,0,1]
  $pos=Numo::SFloat[0,4,10]
  $rot=[0,0,0]
  $trans=Numo::SFloat[0,0,-10]
  $dir=Numo::SFloat[0,0,-1]
  glfwInit()
  b=Obj.new("blenderhousetrimine2.obj")
  a=Obj.new("blockychar.obj")
  b.models.keys.sort_by! {|x| 1 - b.models[x].mat.d}
  a.move([5,0,-10],[0,90,0])
  b.move([5,0,-10],[0,0,0])
  c=Scene.new
  c.env("house",b)
  c.actor("troll",a)
  10.times {|x| GC.start}
  glfwWindowHint(GLFW_SAMPLES,8)
  window = glfwCreateWindow( 640, 480, "Simple example", nil, nil )
  glfwMakeContextCurrent( window )
  glfwSetKeyCallback( window, key_callback )
  glEnable(GL_CULL_FACE)
  glShadeModel(GL_SMOOTH)
  glEnable(GL_DEPTH_TEST)
  glEnable(GL_BLEND)
  glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA)
  glEnable(GL_MULTISAMPLE)
  glfwSwapInterval(1)
  glDisable(GL_COLOR_MATERIAL)
  global_ambient = [0.1, 0.1, 0.1, 1.0] # Set Ambient Lighting To Fairly Dark Light (No Color)   
  light0pos = [0.0, 5.0, -5.0, 1.0] # Set The Light Position   
  light0ambient = [0.1, 0.1, 0.1, 1.0] # More Ambient Light   
  light0diffuse = [0.3, 0.3, 0.3, 1.0] # Set The Diffuse Light A Bit Brighter   
  light0specular = [0.3, 0.3, 0.5, 1.0] # Fairly Bright Specular Lighting   
#  lmodel_ambient = [0.1,0.1,0.1,1.0] # And More Ambient Light
  light0dir = [0.01,-1.0,0.1]
#  glLightModelfv(GL_LIGHT_MODEL_AMBIENT,lmodel_ambient.pack('F*')) # Set The Ambient Light Model   
  glLightModelfv(GL_LIGHT_MODEL_AMBIENT,global_ambient.pack('F*')) # Set The Global Ambient Light Model   
  glLightfv(GL_LIGHT0, GL_POSITION, light0pos.pack('F*')) # Set The Lights Position   
  glLightfv(GL_LIGHT0, GL_AMBIENT, light0ambient.pack('F*'))    # Set The Ambient Light   
  glLightfv(GL_LIGHT0, GL_DIFFUSE, light0diffuse.pack('F*')) # Set The Diffuse Light   
  glLightfv(GL_LIGHT0, GL_SPECULAR, light0specular.pack('F*'))  # Set Up Specular Lighting
  glLightfv(GL_LIGHT0, GL_SPOT_DIRECTION, light0dir.pack('F*'))
  glLightfv(GL_LIGHT0, GL_SPOT_CUTOFF,[90.0].pack('F'))
  glEnable(GL_LIGHTING) # Enable Lighting   
  glEnable(GL_LIGHT0) # Enable Light0   
#  glMateriali(GL_FRONT, GL_SHININESS, 128) 
  glClearColor(0,0,0,1)
  verts={}
  indices={}
  c.objs.keys.each do |x|
    verts[x] = c.objs[x].v.flatten.to_a.pack('F*')
    GC.start
    indices[x] = {}
    c.objs[x].models.keys.each do |y|
      indices[x][y] = c.objs[x].models[y].faces.flatten.to_a.pack('I*')
      GC.start
    end
  end

  glEnableClientState(GL_VERTEX_ARRAY)

  while glfwWindowShouldClose( window ) == 0
    width_ptr = ' ' * 8
    height_ptr = ' ' * 8
    glfwGetFramebufferSize(window, width_ptr, height_ptr)
    width = width_ptr.unpack('L')[0]
    height = height_ptr.unpack('L')[0]
    ratio = width.to_f / height.to_f

    glViewport(0, 0, width, height)
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    glMatrixMode(GL_PROJECTION)
    glLoadIdentity()
#    glFrustum(-1,1,-1,1,1.0,1000.0)
    GLU.gluPerspective(60.0,ratio,0.1,1000.0)
    glMatrixMode(GL_MODELVIEW)
    glLoadIdentity()
    tmp=glfwGetTime()
 #   $rot[1]=tmp*10
 #   GLU.gluLookAt(*rotateall($pos,[0,0,0],$rot),*b.center,0,1,0)
    GLU.gluLookAt(*$pos,*($pos+$dir),0,1,0)
    c.draw(mydraw,verts,indices)
    
    glLightfv(GL_LIGHT0, GL_POSITION, light0pos.pack('F*'))
    glLightfv(GL_LIGHT0, GL_SPOT_DIRECTION, light0dir.pack('F*'))
    
    glfwSwapBuffers( window )
    glfwPollEvents()
  end

  glfwDestroyWindow( window )
  glfwTerminate()
end

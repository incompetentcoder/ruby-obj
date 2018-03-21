#
# For more samples, visit https://github.com/vaiorabbit/ruby-opengl/tree/master/sample .
#
# Ref.: /glfw-3.0.1/examples/simple.c
#
require 'pry'
require 'opengl'
require 'glu'
require 'sdl2'
load '../ruby-obj.rb'


OpenGL.load_lib()
GLU.load_lib()

include OpenGL
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

messages=["SPACE to start pry console","LEFT/RIGHT to rotate left/right","UP/DOWN to rotate up/down","W/S to move forward/backard","A/D to strafe left/right","Q/E to move up/down","ENTER to reset position"]


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
  $steplr=Numo::SFloat[0.5,0,0.5]
  $stepud=Numo::SFloat[0,0.5,0]
  $pos=Numo::SFloat[0,4,10]
  $rot=[0,0,0]
  $trans=Numo::SFloat[0,0,-10]
  $dir=Numo::SFloat[0,0,-1]
  b=Obj.new("blenderhousetrimine2.obj")
  a=Obj.new("blockychar.obj")
  b.models.keys.sort_by! {|x| 1 - b.models[x].mat.d}
  a.move([5,0,-10],[0,90,0])
  b.move([5,0,-10],[0,0,0])
  c=Scene.new
  c.env("house",b)
  c.actor("troll",a)
  10.times {|x| GC.start}
  SDL2.init(SDL2::INIT_EVERYTHING)
  SDL2::GL.set_attribute(SDL2::GL::RED_SIZE, 8)
  SDL2::GL.set_attribute(SDL2::GL::GREEN_SIZE, 8)
  SDL2::GL.set_attribute(SDL2::GL::BLUE_SIZE, 8)
  SDL2::GL.set_attribute(SDL2::GL::ALPHA_SIZE, 8)
  SDL2::GL.set_attribute(SDL2::GL::DOUBLEBUFFER, 1)
  SDL2::GL.set_attribute(SDL2::GL::MULTISAMPLEBUFFERS, 1)
  SDL2::GL.set_attribute(SDL2::GL::MULTISAMPLESAMPLES, 4)
  WINDOW_W=640
  WINDOW_H=480
  ratio=WINDOW_W/WINDOW_H
  window = SDL2::Window.create("testgl", 0, 0, WINDOW_W, WINDOW_H, SDL2::Window::Flags::OPENGL)
  context = SDL2::GL::Context.create(window)
  SDL2::GL.swap_interval=1
  glEnable(GL_CULL_FACE)
  glShadeModel(GL_SMOOTH)
  glEnable(GL_DEPTH_TEST)
  glEnable(GL_BLEND)
  glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA)
  glDisable(GL_COLOR_MATERIAL)
  global_ambient = [0.1, 0.1, 0.1, 1.0] # Set Ambient Lighting To Fairly Dark Light (No Color)   
  light0pos = [0.0, 5.0, -5.0, 1.0] # Set The Light Position   
  light0ambient = [0.1, 0.1, 0.1, 1.0] # More Ambient Light   
  light0diffuse = [0.3, 0.3, 0.3, 1.0] # Set The Diffuse Light A Bit Brighter   
  light0specular = [0.3, 0.3, 0.5, 1.0] # Fairly Bright Specular Lighting   
  light0dir = [0.01,-1.0,0.1]
  glLightModelfv(GL_LIGHT_MODEL_AMBIENT,global_ambient.pack('F*')) # Set The Global Ambient Light Model   
  glLightfv(GL_LIGHT0, GL_POSITION, light0pos.pack('F*')) # Set The Lights Position   
  glLightfv(GL_LIGHT0, GL_AMBIENT, light0ambient.pack('F*'))    # Set The Ambient Light   
  glLightfv(GL_LIGHT0, GL_DIFFUSE, light0diffuse.pack('F*')) # Set The Diffuse Light   
  glLightfv(GL_LIGHT0, GL_SPECULAR, light0specular.pack('F*'))  # Set Up Specular Lighting
  glLightfv(GL_LIGHT0, GL_SPOT_DIRECTION, light0dir.pack('F*'))
  glLightfv(GL_LIGHT0, GL_SPOT_CUTOFF,[90.0].pack('F'))
  glEnable(GL_LIGHTING) # Enable Lighting   
  glEnable(GL_LIGHT0) # Enable Light0   
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
  

  loop do
    while event = SDL2::Event.poll
      case event
      when SDL2::Event::KeyDown
        case event.scancode
        when SDL2::Key::Scan::ESCAPE
          exit
        when SDL2::Key::Scan::LEFT
          $dir = norm(rotatey($dir,2))
        when SDL2::Key::Scan::RIGHT
          $dir = norm(rotatey($dir,-2))
        when SDL2::Key::Scan::UP
          $dir = norm(rotatex($dir,2))
        when SDL2::Key::Scan::DOWN
          $dir = norm(rotatex($dir,-2))
        when SDL2::Key::Scan::W
          $pos = $pos + $dir
        when SDL2::Key::Scan::S
          $pos = $pos - $dir
        when SDL2::Key::Scan::A
          $pos = $pos + norm(rotatey($dir,90))*$steplr
        when SDL2::Key::Scan::D
          $pos = $pos + norm(rotatey($dir,-90))*$steplr
        when SDL2::Key::Scan::Q
          $pos = $pos + $stepud
        when SDL2::Key::Scan::E
          $pos = $pos - $stepud
        when SDL2::Key::Scan::RETURN
          $pos = Numo::SFloat[0,4,10]
          $dir = Numo::SFloat[0,0,-1]
        end
      end
    end

    glViewport(0, 0, WINDOW_W, WINDOW_H)
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    glMatrixMode(GL_PROJECTION)
    glLoadIdentity()
    GLU.gluPerspective(60.0,ratio,0.1,1000.0)
    glMatrixMode(GL_MODELVIEW)
    glLoadIdentity()
    GLU.gluLookAt(*$pos,*($pos+$dir),0,1,0)
    
    glLightfv(GL_LIGHT0, GL_POSITION, light0pos.pack('F*'))
    glLightfv(GL_LIGHT0, GL_SPOT_DIRECTION, light0dir.pack('F*'))

    c.draw(mydraw,verts,indices)

    window.gl_swap  
  end
end

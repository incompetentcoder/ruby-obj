#
# For more samples, visit https://github.com/vaiorabbit/ruby-opengl/tree/master/sample .
#
# Ref.: /glfw-3.0.1/examples/simple.c
#
require 'pry'
require 'opengl'
require 'gosu'
require 'glu'
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

$messages=["SPACE to start pry console","LEFT/RIGHT to rotate left/right","UP/DOWN to rotate up/down","W/S to move forward/backard","A/D to strafe left/right","Q/E to move up/down","ENTER to reset position"]

# Press ESC to exit.

$mydraw = Proc.new {|x,name,verts,indices|
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
  $messages.each {|x| pp x}
  $steplr=Numo::SFloat[0.5,0,0.5]
  $stepud=Numo::SFloat[0,0.5,0]
  $pos=Numo::SFloat[0,4,10]
  $rot=[0,0,0]
  $trans=Numo::SFloat[0,0,-10]
  $dir=Numo::SFloat[0,0,-1]
  class Window < Gosu::Window
    def initialize
      super(640,480)
      self.caption="simple"
      self.update_interval=20
      @font=Gosu::Font.new(14)
      global_ambient = [0.1, 0.1, 0.1, 1.0] # Set Ambient Lighting To Fairly Dark Light (No Color)   
      $light0pos = [0.0, 5.0, -5.0, 1.0] # Set The Light Position   
      light0ambient = [0.1, 0.1, 0.1, 1.0] # More Ambient Light   
      light0diffuse = [0.3, 0.3, 0.3, 1.0] # Set The Diffuse Light A Bit Brighter   
      light0specular = [0.3, 0.3, 0.5, 1.0] # Fairly Bright Specular Lighting   
    #  lmodel_ambient = [0.1,0.1,0.1,1.0] # And More Ambient Light
      $light0dir = [0.01,-1.0,0.1]
    #  glLightModelfv(GL_LIGHT_MODEL_AMBIENT,lmodel_ambient.pack('F*')) # Set The Ambient Light Model   
      glLightModelfv(GL_LIGHT_MODEL_AMBIENT,global_ambient.pack('F*')) # Set The Global Ambient Light Model   
      glLightfv(GL_LIGHT0, GL_POSITION, $light0pos.pack('F*')) # Set The Lights Position   
      glLightfv(GL_LIGHT0, GL_AMBIENT, light0ambient.pack('F*'))    # Set The Ambient Light   
      glLightfv(GL_LIGHT0, GL_DIFFUSE, light0diffuse.pack('F*')) # Set The Diffuse Light   
      glLightfv(GL_LIGHT0, GL_SPECULAR, light0specular.pack('F*'))  # Set Up Specular Lighting
      glLightfv(GL_LIGHT0, GL_SPOT_DIRECTION, $light0dir.pack('F*'))
      glLightfv(GL_LIGHT0, GL_SPOT_CUTOFF,[90.0].pack('F'))
#      glEnable(GL_LIGHTING) # Enable Lighting   
#      glEnable(GL_LIGHT0) # Enable Light0   
    #  glMateriali(GL_FRONT, GL_SHININESS, 128) 
      glClearColor(0,0,0,1)
      b=Obj.new("blenderhousetrimine2.obj")
      a=Obj.new("blockychar.obj")
      d=Obj.new("blenderhousetrimine2.obj")
      b.models.keys.sort_by! {|x| 1 - b.models[x].mat.d}
      a.move([5,0,-10],[0,90,0])
      b.move([5,0,-10],[0,0,0])
      d.move([4,0,-35],[0,0,0])
      @c=Scene.new
      @c.env("house1",b)
      @c.env("house2",d)
      @c.actor("troll",a)
      10.times {|x| GC.start}

      @verts={}
      @indices={}
      @c.objs.keys.each do |x|
        @verts[x] = @c.objs[x].v.flatten.to_a.pack('F*')
        GC.start
        @indices[x] = {}
        @c.objs[x].models.keys.each do |y|
          @indices[x][y] = @c.objs[x].models[y].faces.flatten.to_a.pack('I*')
          GC.start
        end
      end

      glEnableClientState(GL_VERTEX_ARRAY)
    end

    def update
      if Gosu.button_down? Gosu::KB_LEFT
        $dir = norm(rotatey($dir,2))
      end
      if Gosu.button_down? Gosu::KB_RIGHT
        $dir = norm(rotatey($dir,-2))
      end
      if Gosu.button_down? Gosu::KB_UP
        $dir = norm(rotatex($dir,2))
      end
      if Gosu.button_down? Gosu::KB_DOWN
        $dir = norm(rotatex($dir,-2))
      end
      if Gosu.button_down? Gosu::KB_W
        $pos = $pos + $dir
      end
      if Gosu.button_down? Gosu::KB_S
        $pos = $pos - $dir
      end
      if Gosu.button_down? Gosu::KB_A
        $pos = $pos + norm(rotatey($dir,90))*$steplr
      end
      if Gosu.button_down? Gosu::KB_D
        $pos = $pos + norm(rotatey($dir,-90))*$steplr
      end
      if Gosu.button_down? Gosu::KB_Q
        $pos = $pos + $stepud
      end
      if Gosu.button_down? Gosu::KB_E
        $pos = $pos - $stepud
      end
      if Gosu.button_down? Gosu::KB_RETURN
        $pos = Numo::SFloat[0,4,10]
        $dir = Numo::SFloat[0,0,-1]
      end
    end


    def draw
      $messages.each_with_index do |x,y|
        @font.draw(x,10,5+15*y,1,1.0,1.0,Gosu::Color::WHITE)
      end
      Gosu.gl(0) do
        glEnable(GL_LIGHTING) # Enable Lighting   
        glEnable(GL_LIGHT0) # Enable Light0   

        glEnable(GL_CULL_FACE)
        glShadeModel(GL_SMOOTH)
        glEnable(GL_DEPTH_TEST)
        glEnable(GL_BLEND)
        glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA)
        glClearColor(0,0,0,1)
#        glViewport(0, 0, width, height)
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
        glMatrixMode(GL_PROJECTION)
        glLoadIdentity()
        GLU.gluPerspective(65.0,width/height,0.1,1000.0)
        glMatrixMode(GL_MODELVIEW)
        glLoadIdentity()
     #   $rot[1]=tmp*10
     #   GLU.gluLookAt(*rotateall($pos,[0,0,0],$rot),*b.center,0,1,0)
        GLU.gluLookAt(*$pos,*($pos+$dir),0,1,0)
        
        glLightfv(GL_LIGHT0, GL_POSITION, $light0pos.pack('F*'))
        glLightfv(GL_LIGHT0, GL_SPOT_DIRECTION, $light0dir.pack('F*'))

        @c.draw($mydraw,@verts,@indices)
      end

    end

    def button_down(id)
      if id == Gosu::KB_ESCAPE
        close
      elsif id == Gosu::KB_SPACE
        binding.pry
      end
    end
  end

  window = Window.new
  window.show

end



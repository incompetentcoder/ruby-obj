#
# For more samples, visit https://github.com/vaiorabbit/ruby-opengl/tree/master/sample .
#
# Ref.: /glfw-3.0.1/examples/simple.c
#
require 'pry'
require 'opengl'
require 'glu'
require 'sdl'
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

$messages=["SPACE to start pry console","LEFT/RIGHT to rotate left/right","UP/DOWN to rotate up/down","W/S to move forward/backward","A/D to strafe left/right","Q/E to move up/down","ENTER to reset position"]


mydraw = Proc.new {|x,name,verts,indices|
      if x.faces
        if x.parent.vn
          glEnableClientState(GL_NORMAL_ARRAY)
          glNormalPointer(GL_FLOAT,0,$norms[name])
        end

        #
    glPushMatrix()
    glTranslatef(*x.parent.pos)
    glRotatef(x.parent.rot[0],0,1,0)
#    glTranslatef(*x.parent.pos)
        #
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
      glPopMatrix()
      glDisableClientState(GL_NORMAL_ARRAY)

}

if __FILE__ == $0
#  $pos=Numo::SFloat[5,10,15]
#  $rot=[0,0,1,0]
 $texture=[]
 $tex=[]
 $texid=[]

 $messages.each {|x| pp x}
  $steplr=Numo::SFloat[0.2,0,0.2]
  $stepud=Numo::SFloat[0,0.2,0]
  $stepfb=Numo::SFloat[0.4,0.4,0.4]
  $pos=Numo::SFloat[0,4,10]
  $rot=[0,0,0]
  $trans=Numo::SFloat[0,0,-10]
  $dir=Numo::SFloat[0,0,-1]
  lr=0
  ud=0
  fb=0
  slr=0
  sud=0
  b=Obj.new("blenderhousetrimine2.obj")
  a=Obj.new("srtroll2.obj")
  d=Obj.new("blenderhousetrimine2.obj")
  e=Obj.new("blenderhousetrimine2.obj")
  f=Obj.new("blenderhousetrimine2.obj")
  g=Obj.new("blockychar.obj")
#  a.move([10,0,-5],[0,90,0])
  b.move([10,0,-10],[0,0,0])
  d.move([10,0,-35],[0,0,0])
  e.move([-15,0,-10],[0,0,0])
  f.move([-15,0,-35],[0,0,0])
  $c=Scene.new
  $c.env("house1",b)
  $c.env("house2",d)
  $c.env("house3",e)
  $c.env("house4",f)
  $c.actor("troll",a)
  10.times {|x| GC.start}
  SDL.init(SDL::INIT_EVERYTHING)
  SDL::GL.set_attr(SDL::GL::RED_SIZE, 8)
  SDL::GL.set_attr(SDL::GL::GREEN_SIZE, 8)
  SDL::GL.set_attr(SDL::GL::BLUE_SIZE, 8)
  SDL::GL.set_attr(SDL::GL::ALPHA_SIZE, 8)
  SDL::GL.set_attr(SDL::GL::DOUBLEBUFFER, 1)
  SDL::GL.set_attr(SDL::GL::MULTISAMPLEBUFFERS, 1)
  SDL::GL.set_attr(SDL::GL::MULTISAMPLESAMPLES, 4)
  
  $verts={}
  $indices={}
  window_W=640
  window_H=480
  scalex=1.0
  scaleh=1.0
  ratio=window_W/window_H


  def init(window_W,window_H)
    SDL::Screen.open window_W,window_H,0,SDL::OPENGL|SDL::RESIZABLE
    ratio=window_W/window_H

#  window = SDL2::Window.create("testgl", 0, 0, window_W, window_H, SDL2::Window::Flags::OPENGL)
#  context = SDL2::GL::Context.create(window)

    glEnable(GL_CULL_FACE)
    glShadeModel(GL_SMOOTH)
    glEnable(GL_DEPTH_TEST)
    glEnable(GL_BLEND)
    glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA)
    glDisable(GL_COLOR_MATERIAL)
    global_ambient = [0.1, 0.1, 0.1, 1.0] # Set Ambient Lighting To Fairly Dark Light (No Color)   
    $light0pos = [0.0, 8.1, -10.1, 1.0] # Set The Light Position   
    light0ambient = [0.1, 0.1, 0.1, 1.0] # More Ambient Light   
    light0diffuse = [0.3, 0.3, 0.3, 1.0] # Set The Diffuse Light A Bit Brighter   
    light0specular = [0.3, 0.3, 0.5, 1.0] # Fairly Bright Specular Lighting   
    $light0dir = [0.01,-1.0,0.1]
    glLightModelfv(GL_LIGHT_MODEL_AMBIENT,global_ambient.pack('F*')) # Set The Global Ambient Light Model   
    glLightfv(GL_LIGHT0, GL_POSITION, $light0pos.pack('F*')) # Set The Lights Position   
    glLightfv(GL_LIGHT0, GL_AMBIENT, light0ambient.pack('F*'))    # Set The Ambient Light   
    glLightfv(GL_LIGHT0, GL_DIFFUSE, light0diffuse.pack('F*')) # Set The Diffuse Light   
    glLightfv(GL_LIGHT0, GL_SPECULAR, light0specular.pack('F*'))  # Set Up Specular Lighting
    glLightfv(GL_LIGHT0, GL_SPOT_DIRECTION, $light0dir.pack('F*'))
    glLightfv(GL_LIGHT0, GL_SPOT_CUTOFF,[90.0].pack('F'))
    glEnable(GL_LIGHTING) # Enable Lighting   
    glEnable(GL_LIGHT0) # Enable Light0   
    glClearColor(0,0,0,1)
    $verts={}
    $indices={}
    $norms={}
    $c.objs.keys.each do |x|
      $verts[x] = $c.objs[x].v.flatten.to_a.pack('F*')

      $norms[x] = $c.objs[x].vn.flatten.to_a.pack('F*') if $c.objs[x].vn #testing vertex normals

      GC.start
      $indices[x] = {}
      $c.objs[x].models.keys.each do |y|
        $indices[x][y] = $c.objs[x].models[y].faces.flatten.to_a.pack('I*')
        GC.start
      end
    end
    glEnableClientState(GL_VERTEX_ARRAY)
#    SDL::Key.enableKeyRepeat(10,10)
     SDL::Key.disableKeyRepeat 
  end

  init(window_W,window_H)

  SDL::TTF.init
  font=SDL::TTF.open("DejaVuSansMono.ttf",12,0)
  font.hinting=SDL::TTF::HINTING_MONO
  fw,fh = font.text_size("a")
  $messages.size.times do |x|
    w,h = font.text_size($messages[x])
    tmp = font.render_blended_utf8($messages[x],255,255,255)
    $texture = tmp.display_format_alpha
    $tex[x] = ' ' * 4
    glGenTextures(1, $tex[x])
    $texid[x] = $tex[x].unpack('L')[0]
    glBindTexture(GL_TEXTURE_2D, $texid[x])
    glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA,w,h,0,GL_RGBA,GL_UNSIGNED_BYTE,$texture.pixels)
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
    glGenerateMipmap(GL_TEXTURE_2D)
    glBindTexture(GL_TEXTURE_2D, 0)
    $texture.destroy
  end
  ticks = SDL::get_ticks
  
  a.pos=Numo::SFloat[10,0,-10]
  a.rot=[0,0,0]
  loop do
    while event = SDL::Event.poll
 #   event = SDL::Event.wait
      case event
      when SDL::Event::KeyDown
        case event.sym
        when SDL::Key::ESCAPE
          exit
        when SDL::Key::LEFT
		lr=1
	when SDL::Key::RIGHT
		lr=-1
	when SDL::Key::UP
		ud=1
	when SDL::Key::DOWN
		ud=-1
	when SDL::Key::W
		fb=1
	when SDL::Key::S
		fb=-1
	when SDL::Key::A
		slr=1
	when SDL::Key::D
		slr=-1
	when SDL::Key::Q
		sud=1
	when SDL::Key::E
		sud=-1
	when SDL::Key::RETURN
		$pos=Numo::SFloat[0,4,10]
		$dir=Numo::SFloat[0,0,-1]
	end
      when SDL::Event::KeyUp
	      case event.sym
	      when SDL::Key::LEFT,SDL::Key::RIGHT
		      lr=0
	      when SDL::Key::UP,SDL::Key::DOWN
		      ud=0
	      when SDL::Key::W,SDL::Key::S
		      fb=0
	      when SDL::Key::A,SDL::Key::D
		      slr=0
	      when SDL::Key::Q,SDL::Key::E
		      sud=0
	      end


      when SDL::Event::VideoResize
        window_W,window_H = event.w,event.h
        ratio = window_W/window_H
        SDL::Screen.open(window_W,window_H,0,SDL::OPENGL|SDL::RESIZABLE)
        init(window_W,window_H)
        scalex=window_W/640.0
        scaleh=window_H/480.0
      end
    end
#    SDL::Key.scan
    

    a.rot[0] > 360 ? a.rot[0]=5 : a.rot[0]+=5

=begin
    lr+=1 if SDL::Key.press?(SDL::Key::LEFT)
          #$dir = norm(rotatey($dir,2))
    lr-=1 if SDL::Key.press?(SDL::Key::RIGHT)
          #$dir = norm(rotatey($dir,-2))
    ud+=1 if SDL::Key.press?(SDL::Key::UP)
          #$dir = norm(rotatex($dir,2))
    ud-=1 if SDL::Key.press?(SDL::Key::DOWN)
          #$dir = norm(rotatex($dir,-2))
    fb+=1 if SDL::Key.press?(SDL::Key::W)
          #$pos = $pos + $dir
    fb-=1 if SDL::Key.press?(SDL::Key::S)
          #$pos = $pos - $dir
    slr+=1 if SDL::Key.press?(SDL::Key::A)
          #$pos = $pos + norm(rotatey($dir,90))*$steplr
    slr-=1 if SDL::Key.press?(SDL::Key::D)
          #$pos = $pos + norm(rotatey($dir,-90))*$steplr
    sud+=1 if SDL::Key.press?(SDL::Key::Q)
          #$pos = $pos + $stepud
    sud-=1 if SDL::Key.press?(SDL::Key::E)
          #$pos = $pos - $stepud
    if SDL::Key.press?(SDL::Key::RETURN)
      $pos = Numo::SFloat[0,4,10]
      $dir = Numo::SFloat[0,0,-1]
    end
=end
    if lr != 0
      $dir = norm(rotatey($dir,lr))
    end
    if ud != 0
      $dir = norm(rotatex($dir,ud))
    end
    if fb != 0
      $pos = $pos + $dir*fb*$stepfb
    end
    if slr != 0
      $pos = $pos + slr*norm(rotatey($dir,90))*$steplr
    end
    if sud != 0
      $pos = $pos + sud*$stepud
    end
#    lr = ud = fb = slr = sud = 0
    
    glEnable(GL_LIGHTING)
    glViewport(0, 0, window_W, window_H)
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    glMatrixMode(GL_PROJECTION)
    glLoadIdentity()
    GLU.gluPerspective(60.0,ratio,0.1,1000.0)
    glMatrixMode(GL_MODELVIEW)
    glLoadIdentity()
    GLU.gluLookAt(*$pos,*($pos+$dir),0,1,0)
    glLightfv(GL_LIGHT0, GL_POSITION, $light0pos.pack('F*'))
    glLightfv(GL_LIGHT0, GL_SPOT_DIRECTION, $light0dir.pack('F*'))

#    glPushMatrix()
    
    $c.draw(mydraw,$verts,$indices)

    glMatrixMode(GL_PROJECTION)
    glLoadIdentity()
    gluOrtho2D(0, window_W, 0, window_H)
    glMatrixMode(GL_MODELVIEW)
    glLoadIdentity()
    glDisable(GL_LIGHTING)

#    glRotatef(45, 0.0, 0.0, 1.0)
    x = 0
    while x < $messages.length do
      glEnable(GL_TEXTURE_2D)
      glBindTexture(GL_TEXTURE_2D, $texid[x])
      glBegin(GL_QUADS)
    
      glTexCoord2f(0.0, 0.0)
      glVertex2i(0.0, window_H-x*fh*scaleh)
    
      glTexCoord2f(0.0, 1.0)
      glVertex2i(0.0, window_H-(x+1)*fh*scaleh)
    
      glTexCoord2f(1.0, 1.0)
      glVertex2i($messages[x].length*fw*scalex, window_H-(x+1)*fh*scaleh)
    
      glTexCoord2f(1.0, 0.0)
      glVertex2i($messages[x].length*fw*scalex, window_H-x*fh*scaleh)
      glEnd()
      glBindTexture(GL_TEXTURE_2D,0)
      x+=1
    end

    last = SDL::get_ticks
    delay = last - ticks
#    sleep(delay*0.001) if delay > 0
    if delay < 14
    	SDL.delay(16 - delay)
    end
    ticks=SDL::get_ticks


    SDL::GL.swap_buffers

  end
end

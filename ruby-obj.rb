#require 'pry'
#require 'free-image'
require 'numo/narray'
$errors=["file not found".freeze,"unsupported mtl options".freeze,
         "unsupported texture options".freeze,"unsupported shapes/bezier/curves".freeze]

def transverts(v,rot,trans)
  rottransm=Numo::SFloat.cast([[1,0,0,trans[0]],
                              [0,Math::cos(rot),-Math::sin(rot),trans[1]],
                              [0,Math::sin(rot),Math::cos(rot),trans[2]],
                              [0,0,0,1]])
  v.shape[0].times {|x| v[x,0..-1] = Numo::SFloat[*v[x,0..-1],1].inner(rottransm)[0..2]}
end

def rotateall(v,trans,rot)
  r=rot.map {|x| x/57.29577951308232}
  sina=Math::sin(r[0])
  cosa=Math::cos(r[0])
  sinb=Math::sin(r[1])
  cosb=Math::cos(r[1])
  sinc=Math::sin(r[2])
  cosc=Math::cos(r[2])
  rottransm=Numo::SFloat.cast(
    [[cosb*cosc,-cosb*sinc,sinb,trans[0]],
    [cosa*sinc+sina*sinb*cosc,cosa*cosc-sina*sinb*sinc,-sina*cosb,trans[1]],
    [sina*sinc-cosa*sinb*cosc,sina*cosc+cosa*sinb*sinc,cosa*cosb,trans[2]],
    [0,0,0,1]])
  GC.start
  if v.class == Obj
    v.v.shape[0].times {|x| v.v[x,0..-1] = Numo::SFloat[*v.v[x,0..-1],1].inner(rottransm)[0..2]}
    GC.start
    v.center = Numo::SFloat[*v.center[0..-1],1].inner(rottransm)[0..2]
    calcminmax(v)
    v.models.keys.each do |x|
      if v.models[x].faces
        calcminmax(v.models[x])
        bsphere(v.models[x])
        v.models[x].facenormals
      end
      GC.start
    end
  end
  GC.start
end

def transcam(obj,cam)
  e = cam[0,0..-1] #origin
  d = cam[1,0..-1] #direction
  u = Numo::SFloat[0,1,0] #up
  r = cross(d,u)
  u = cross(r,d)
  d = norm(d)
  r = norm(r)
  u = norm(u)
  rottransm = Numo::SFloat.cast([[*r,r.dot(e*-1)],[*u,u.dot(e*-1)],[*(d*-1),d.dot(e*-1)],[0,0,0,1]])
  trans = Numo::SFloat.cast(obj.collect {|x| x[2]})
  obj[(zsort(Numo::SFloat.cast(trans.split(trans.shape[0]).map {|x| Numo::SFloat.cast([*x.flatten,1]).inner(rottransm)})))[cam[1,2] > 0 ? 0 : -1]]
end

def transall(obj,cam)
  e = cam[0,0..-1] #origin
  d = cam[1,0..-1] #direction
  u = Numo::SFloat[0,1,0] #up
  r = cross(d,u)
  u = cross(r,d)
  d = norm(d)
  r = norm(r)
  u = norm(u)
  rottransm = Numo::SFloat.cast([[*r,r.dot(e*-1)],[*u,u.dot(e*-1)],[*(d*-1),d.dot(e*-1)],[0,0,0,1]])
  if obj.class == Obj
    obj.v.shape[0].times {|x| obj.v[x,0..-1] = Numo::SFloat[*obj.v[x,0..-1],1].inner(rottransm)[0..2]}
  end
end


def calcminmax(obj)
  xmin=ymin=zmin=10000.0
  xmax=ymax=zmax=-10000.0
  if obj.class == Obj
    v = obj.v
    xmin,xmax = v[0..-1,0].minmax
    ymin,ymax = v[0..-1,1].minmax
    zmin,zmax = v[0..-1,2].minmax
  else
    v = obj.faces
    obj.faces.each do |x|
      xmin = obj.parent.v[x,0] if xmin > obj.parent.v[x,0]
      xmax = obj.parent.v[x,0] if xmax < obj.parent.v[x,0]
      ymin = obj.parent.v[x,1] if ymin > obj.parent.v[x,1]
      ymax = obj.parent.v[x,1] if ymax < obj.parent.v[x,1]
      zmin = obj.parent.v[x,2] if zmin > obj.parent.v[x,2]
      zmax = obj.parent.v[x,2] if zmax < obj.parent.v[x,2]
    end
  end
    obj.minv=Numo::SFloat[xmin,ymin,zmin]
    obj.maxv=Numo::SFloat[xmax,ymax,zmax]

end

def bsphere(obj)
  obj.center = (obj.minv + obj.maxv)*0.5
  obj.radius = Numo::SFloat.cast((obj.maxv - obj.minv).max / 2.0)
  obj.r2 = obj.radius.square
end

def zsort(obj)
  if obj.class == Obj
    obj.v[0..-1,2].sort_index
  elsif obj.class == Model
    Numo::SFloat.cast(obj.faces.split(obj.faces.shape[0]).map {|x| x[0,0..-1,2].mean}).sort_index
  elsif obj.class == Numo::SFloat
    obj[0..-1,2].sort_index
  end
end

def norm(u)
  den = u.square.sum ** 0.5
  u/den
end

def cross(u,v)
  tmp = Numo::SFloat[u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0]]
end


class Scene
  attr_accessor :objs
  def raytrace(ray)
    arf=[]
    tmp = @objs.keys.select {|x| @objs[x].class == Obj}
    tmp.each do |x|
      tmp2 = @objs[x].raytrace(ray)
      if tmp2 != [] && tmp2 != nil
        tmp2.each {|y| arf << y}
      end
    end
    arf.sort_by! {|x| x[2].sum}
    arf.reverse! if ray[1,0..-1].sum < 0
    arf
  end

  def initialize
    @objs={}
    @envs=[]
    @actors=[]
  end

  def actor(name,obj)
    @objs[name]=obj
    @actors << name
  end

  def env(name,obj)
    @objs[name]=obj
    @envs << name
  end

  def draw(func)
    @actors.sort_by {|x| @objs[x].center[2]}.each {|x| @objs[x].draw(func)}
    @envs.sort_by {|x| @objs[x].center[2]}.each {|x| @objs[x].draw(func)}
  end
end

class Model
  attr_accessor :mat, :faces, :fc, :parent, :radius, :center, :minv, :maxv, :fn, :name, :r2
  def initialize(parent)
    @parent = parent
  end

  def raytrace(ray)
    isec = []
    if @faces
      ray[1,0..-1] = norm(ray[1,0..-1])
      p = ray[0,0..-1] - @center
      if (p_d = p.dot(ray[1,0..-1])) > 0 || (p.dot(p) < @r2) == 1
        return nil
      end
      a = p - p_d * ray[1,0..-1]
      if a.dot(a) > @r2 == 1
        return nil
      end
      @fn.shape[0].times do |x|
        if (b=@fn[x,0..-1].dot(ray[1,0..-1])).abs < 0.01
          next
        end
        a=@fn[x,0..-1].dot(ray[0,0..-1]-@parent.v[@faces[x,0],0..-1]) * -1
        if (r = a/b) < 0.0
          next
        end
        i = ray[0,0..-1] + r * ray[1,0..-1]
        if @faces.shape[1] == 3
          u = @parent.v[@faces[x,1],0..-1] - @parent.v[@faces[x,0],0..-1]
          v = @parent.v[@faces[x,2],0..-1] - @parent.v[@faces[x,0],0..-1]
          uu = u.dot(u)
          uv = u.dot(v)
          vv = v.dot(v)
          w = i - @parent.v[@faces[x,0],0..-1]
          wu = w.dot(u)
          wv = w.dot(v)
          d = uv * uv - uu * vv
          s=(uv*wv - vv*wu)/d
          if s < 0.0 || s > 1.0
            next
          end
          t = (uv*wu - uu*wv)/d
          if t < 0.0 || (s+t) > 1.0
            next
          end
        else
          next
        end
        isec << [@name,x,i]
      end
    end
    isec.empty? ? nil : transcam(isec,ray)
  end
    
  def facenormals
    @fn = Numo::SFloat.new(@faces.shape[0],3).allocate
    @faces.shape[0].times do |p|
      u = @parent.v[faces[p,1],0..-1] - @parent.v[faces[p,0],0..-1]
      v = @parent.v[faces[p,2],0..-1] - @parent.v[faces[p,0],0..-1]
      tmp = Numo::SFloat[u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0]]
      den = tmp.square.sum ** 0.5
      @fn[p,0..-1] = (tmp / den)
    end
  end
end

class Material
  attr_accessor :Ka, :Kd, :Ks, :d, :Ns, :illum,
    :map_Ka, :map_Kd, :map_Ks, :map_d, :image
end

class Obj
  attr_accessor :models, :materials, :v, :vt, :vn, :pos, :rot, :center, :radius, :minv, :maxv, :r2
  def initialize(filename)
    begin
      a=File.open(filename)
    rescue
      error(0)
    end
    @dirname=File.dirname(filename)
    b=a.read
    a.close
    @pos=Numo::SFloat[0,0,0]
    @rot=Numo::SFloat[0,[0,0,0]]
    @models={}
    readobj(b)
    GC.start
    calcminmax(self)
    GC.start
    bsphere(self)
    GC.start
    @models.keys.each do |x|
      if @models[x].faces
        calcminmax(@models[x])
        bsphere(@models[x])
        @models[x].facenormals
      end
      GC.start
     end
  end

  def move(translation=[0,0,0],rotation=[0,0,0])
    if translation != [0,0,0] || rotation != [0,0,0]
      rotateall(self,translation,rotation)
    end
  end

  def draw(func)
    @models.keys.select {|x| @models[x].faces}.sort_by {|x| 1 - @models[x].mat.d}
      .each_with_index {|x| func.call(@models[x],x)}
  end

  def raytrace(ray)
    ray[1,0..-1] = norm(ray[1,0..-1])
    ghtfv(GL_LIGHT0, GL_POSITION, light0pos.pack('F*'))
    p = ray[0,0..-1] - @center
    if (p_d = p.dot(ray[1,0..-1])) > 0 || (p.dot(p) < @r2) == 1
      return nil
    end
    a = p - p_d * ray[1,0..-1]
    if a.dot(a) > @r2 == 1
      return nil
    end

    arf = []
    tmp = @models.keys.select {|x| @models[x].faces}
      .sort_by {|x| ((@models[x].center + @models[x].radius*(ray[1,0..-1]*-1)) - ray[0,0..-1]).sum}
    tmp.reverse! if ray[1,0..-1].sum < 0
    tmp.each do |x|
      tmp2 = @models[x].raytrace(ray)
      if tmp2 != nil
        arf << tmp2
        if (@models[x].mat && @models[x].mat.d == 1)
          break
        end
      end
    end
    arf
  end
  
  def readobj(b)
    materialfile = b.scan(/^mtllib ([^\r\n]*)/).join
    puts materialfile
    if materialfile
      @materials={}
      readmtl(File.expand_path(materialfile,@dirname))
    else
      @hasmaterials=false
    end
    
    if b.index(/^(vp|cstype|deg|curv2|parm|surf|curv|trim) /)
      error(3)
    end
    @v=Numo::SFloat.parse(b.scan(/^v ([^\r\n]*)/).join("\n"))
    
    if b.index(/^vt /)
      @vt = Numo::SFloat.parse(b.scan(/^vt ([^\r\n]*)/).join("\n"))
    end
    
    if b.index(/^vn /)
      @vn = Numo::SFloat.parse(b.scan(/^vn ([^\r\n]*)/).join("\n"))
    end

    if b.index(/^[go] /)
      @hasgroups=true
      parsegroups(b)
    end
  end

  def parsegroups(b)
    groups = b.split(/^[go] /)[1..-1]
    groups.each do |tmp|
      name = tmp.lines[0].chomp.freeze
      cur = (@models[name]=Model.new(self))
      cur.name = name
      if tmp2 = tmp.scan(/usemtl ([^\r\n]*)/)
        cur.mat = @materials[tmp2.flatten[0]]
      end
      if tmp.index(/^f /)
        cur.faces = Numo::UInt32.cast(tmp.scan(/^f ([^\r\n]*)/).map{|y| y[0].split(" ").map{|z| z.split("/")[0].to_i()-1 }})
        cur.fc = cur.faces.shape[0]
      end
    end
  end
  
  def readmtl(mtlfile)
    begin
      a=File.open(mtlfile)
    rescue
      error(0)
    end
    b=a.read.chomp.split("\n")
    a.close
    parsemtl(b)
  end
  
  def parsemtl(mtl)
    mtls=mtl.each_index.select {|x| mtl[x].start_with?("newmtl ")} + [mtl.size]
    (mtls.size() -1).times do |section|
      tmp = mtl[mtls[section]...mtls[section+1]]
      name = tmp[0].gsub("usemtl ",'').gsub("newmtl ",'').chomp
      cur = (@materials[name] = Material.new)
      tmp2=nil
      cur.Ka =  kakdks(tmp.find{|x| x.start_with?("Ka ")})
      cur.Kd = kakdks(tmp.find{|x| x.start_with?("Kd ")})
      cur.Ks = kakdks(tmp.find{|x| x.start_with?("Ks ")})
      cur.illum = ((ttmp = tmp.find{|x| x.start_with?("illum ")}) != nil ? ttmp.split(" ")[1].to_f : nil)
      cur.d = ((ttmp = tmp.find{|x| x.start_with?("d ")}) != nil ? ttmp.split(" ")[1].to_f : nil)
      cur.Ns = ((ttmp = tmp.find{|x| x.start_with?("Ns ")}) != nil ? ttmp.split(" ")[1].to_f : nil)
      cur.map_Ka = mapkakdks(tmp.find{|x| x.start_with?("map_Ka ")})
      cur.map_Kd = mapkakdks(tmp.find{|x| x.start_with?("map_Kd ")})
      cur.map_Ks = mapkakdks(tmp.find{|x| x.start_with?("map_Ks ")})
      cur.map_d = ((ttmp = tmp.find{|x| x.start_with?("map_d ")}) != nil ? ttmp.to_f : nil)
#      if cur.map_Kd
#        cur.image = FreeImage::Bitmap.open(cur.map_Kd)
#      end
    end
  end

  def mapkakdks(line)
    if line
      args = line.split(" ")[1..-1].join
      if args.match(/\-(blendu|blendv|clamp|imfchan|mm|o|s|t|texres) /)
        error(2)
      end
      return File.expand_path(args,@dirname)
    else
      return nil
    end
  end

  def kakdks(line)
    if line
      args = line.split(" ")[1..-1]
      if args.include?("xyz") || args.include?(/\.rfl/)
        error(1)
      end
      args+=[args[0],args[0]] if args.size == 1
      return args.map(&:to_f)
    else
      return nil
    end
  end

  def error(type)
    puts $errors[type]
    exit
  end
  
end





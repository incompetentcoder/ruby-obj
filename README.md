#obj parser and scene tool

wavefront obj/material parser in ruby
only triangles and materials supported, no textures, no shapes

Requirements:
	- numo-narray

sample usage:

load 'ruby-obj'

a=Obj.new("/myobj.obj")

ray = Numo::SFloat[[0,0,1000],[0,0,-1]] # ray 

a.raytrace(ray)

import * as T from 'three'
import { mergeGeometries } from 'three/examples/jsm/utils/BufferGeometryUtils.js'
import { RoundedBoxGeometry } from 'three/examples/jsm/geometries/RoundedBoxGeometry.js'

const cube=new T.BoxGeometry()
const panel=new T.PlaneGeometry()
type Point=[number,number,number]

export class Parts {
  group=new T.Group()
  mesh(geo:T.BufferGeometry, material:T.Material, x:number,y:number,z:number, target?:string) {
    const obj=new T.Mesh(geo,material)
    obj.position.set(x,y,z)
    if(target)obj.userData.target=target
    this.group.add(obj)
    return obj
  }
  box(x:number,y:number,z:number,w:number,h:number,d:number,mat:T.Material,target?:string){
    const obj=this.mesh(cube,mat,x,y,z,target)
    obj.scale.set(w,h,d)
    return obj
  }
  bevel(x:number,y:number,z:number,w:number,h:number,d:number,r:number,mat:T.Material,target?:string){
    return this.mesh(new RoundedBoxGeometry(w,h,d,2,r),mat,x,y,z,target)
  }
  face(x:number,y:number,z:number,w:number,h:number,ry:number,mat:T.Material,target?:string){
    const obj=this.mesh(panel,mat,x,y,z,target)
    obj.scale.set(w,h,1)
    obj.rotation.y=ry
    return obj
  }
  rod(a:Point,b:Point,r:number,mat:T.Material,target?:string,sides=5){
    const p=new T.Vector3(...a), q=new T.Vector3(...b)
    const delta=q.clone().sub(p)
    const center=p.add(q).multiplyScalar(.5)
    const geo=new T.CylinderGeometry(r,r,delta.length(),sides,1,true)
    const obj=this.mesh(geo,mat,center.x,center.y,center.z,target)
    obj.quaternion.setFromUnitVectors(new T.Vector3(0,1,0),delta.normalize())
    return obj
  }
  pipe(points:Point[],r:number,mat:T.Material,target?:string,closed=false){
    const curve=new T.CatmullRomCurve3(points.map(p=>new T.Vector3(...p)),closed,'centripetal')
    const tubular=closed?points.length:Math.max(6,points.length*2)
    return this.mesh(new T.TubeGeometry(curve,tubular,r,4,closed),mat,0,0,0,target)
  }
  batch(){
    const bins=new Map<string,{material:T.Material, geometries:T.BufferGeometry[]}>()
    for(const child of this.group.children){
      if(!(child instanceof T.Mesh))continue
      const mat=child.material as T.Material
      const key=mat.uuid
      if(!bins.has(key)) bins.set(key,{material:mat,geometries:[]})
      child.updateMatrix()
      const geo=child.geometry.index?child.geometry.toNonIndexed():child.geometry.clone()
      geo.applyMatrix4(child.matrix)
      for(const attr of Object.keys(geo.attributes))if(attr!=='position'&&attr!=='normal'&&attr!=='uv')geo.deleteAttribute(attr)
      bins.get(key)!.geometries.push(geo)
    }
    this.group.clear()
    for(const data of bins.values()){
      const geo=mergeGeometries(data.geometries,false)
      if(!geo)throw new Error('Incompatible subway geometry')
      const mesh=new T.Mesh(geo,data.material)
      this.group.add(mesh)
      data.geometries.forEach(g=>g.dispose())
    }
    return this.group
  }
}

export function standard(color:T.ColorRepresentation){
  return new T.MeshLambertMaterial({color})
}

export function seatShell(n=10){
  // The rim rises on either side of a continuous scoop from the backrest to the front lip.
  const contours=[
    [.08,1.01],[.105,1.025],[.133,.99],[.137,.856],[.157,.692],
    [.202,.569],[.302,.487],[.432,.470],[.498,.476],[.548,.482],
    [.572,.463],[.574,.431],[.556,.409],[.399,.400],[.110,.525],[.054,.975],[.08,1.01],
  ]
  const p:number[]=[], idx:number[]=[],uv:number[]=[]
  for(let j=0;j<contours.length;j++){
    const [d,h]=contours[j]
    for(let i=0;i<=n;i++){
      const v=i/n*2-1
      const lip=Math.pow(Math.abs(v),2.4)
      const sideHeight=lip*(j<9?.041:.023)
      p.push(d+lip*(j<5?.075:.014),h+sideHeight,.231*v)
      uv.push(i/n,j/(contours.length-1))
    }
    if(j>0)for(let i=0;i<n;i++){
      const a=(j-1)*(n+1)+i,b=a+n+1
      idx.push(a,a+1,b,a+1,b+1,b)
    }
  }
  const g=new T.BufferGeometry()
  g.setAttribute('position',new T.Float32BufferAttribute(p,3))
  g.setAttribute('uv',new T.Float32BufferAttribute(uv,2))
  g.setIndex(idx)
  g.computeVertexNormals()
  return g
}


// Sheet-metal trim and a radiused rubber gasket wrap the corners of each glazing panel.
export function windowGasket(w:number,h:number,thickness:number,radius:number) {
  const round = (path:T.Path, width:number,height:number,r:number) => {
    const a=width/2,b=height/2
    path.moveTo(-a+r,-b)
    path.lineTo(a-r,-b); path.quadraticCurveTo(a,-b,a,-b+r)
    path.lineTo(a,b-r); path.quadraticCurveTo(a,b,a-r,b)
    path.lineTo(-a+r,b); path.quadraticCurveTo(-a,b,-a,b-r)
    path.lineTo(-a,-b+r); path.quadraticCurveTo(-a,-b,-a+r,-b)
  }
  const shape=new T.Shape(), hole=new T.Path()
  round(shape,w,h,radius)
  round(hole,w-2*thickness,h-2*thickness,Math.max(.015,radius-thickness))
  shape.holes.push(hole)
  return new T.ShapeGeometry(shape,1)
}

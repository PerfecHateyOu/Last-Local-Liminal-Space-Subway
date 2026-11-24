import * as T from 'three'
import { STOPS } from '../../constants'

/** The 13 G stops, in ride order. Index 0 of STOPS is a blank. */
const ROUTE = STOPS.slice(1)

function canvas(width: number, height: number, paint: (c: CanvasRenderingContext2D) => void) {
  const surface = document.createElement('canvas')
  surface.width = width
  surface.height = height
  const c = surface.getContext('2d')!
  paint(c)
  const texture = new T.CanvasTexture(surface)
  texture.colorSpace = T.SRGBColorSpace
  texture.anisotropy = 4
  return texture
}

function noise(seed: number) {
  return () => {
    seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0
    return seed / 4294967296
  }
}

let cachedFloorTex: T.CanvasTexture | null = null
let cachedBrushedTex: T.CanvasTexture | null = null
let cachedGlassTex: T.CanvasTexture | null = null

export function environmentMap() {
  const tex = canvas(768, 384, c => {
    const grad = c.createLinearGradient(0, 0, 0, 384)
    for (const [p, col] of [[0,'#b9bcb7'],[.2,'#e6e7d8'],[.32,'#958f7e'],[.42,'#686556'],[.48,'#252b2c'],[.51,'#88877b'],[.56,'#373d3c'],[.68,'#c48c45'],[.72,'#55524a'],[1,'#30352f']] as const) grad.addColorStop(p,col)
    c.fillStyle = grad
    c.fillRect(0,0,768,384)
    for (let i=0;i<8;i++) {
      c.fillStyle='#fafbec'
      c.fillRect(i*96+6,83,78,10)
      c.fillStyle='#e5e8df'
      c.fillRect(i*96+8,97,73,3)
      c.fillStyle='#1d2626'
      c.fillRect(i*96+8,154,70,44)
      c.fillStyle='#b7b6a8'
      c.fillRect(i*96+80,122,5,114)
    }
  })
  tex.mapping = T.EquirectangularReflectionMapping
  return tex
}

export function floorMaterial() {
  if (!cachedFloorTex) {
    cachedFloorTex = canvas(256, 256, c => {
      const size = 256
      const rnd = noise(64819)
      const img = typeof c.createImageData === 'function' ? c.createImageData(size, size) : null
      if (img) {
        const d = img.data
        for (let i = 0; i < d.length; i += 4) {
          d[i] = 99
          d[i + 1] = 99
          d[i + 2] = 99
          d[i + 3] = 255
        }
        for (let i = 0; i < 12000; i++) {
          const w = rnd() > 0.55 ? 2 : 1
          const h = rnd() > 0.6 ? 2 : 1
          const shade = Math.round(43 + rnd() * 109)
          const x0 = Math.floor(rnd() * (size - w))
          const y0 = Math.floor(rnd() * (size - h))
          for (let dy = 0; dy < h; dy++) {
            for (let dx = 0; dx < w; dx++) {
              const p = ((y0 + dy) * size + (x0 + dx)) * 4
              d[p] = shade
              d[p + 1] = shade
              d[p + 2] = Math.max(0, shade - 2)
            }
          }
        }
        c.putImageData(img, 0, 0)
      } else {
        c.fillStyle = '#636363'
        c.fillRect(0, 0, size, size)
      }
      c.strokeStyle = 'rgba(38,37,35,.44)'
      c.lineWidth = 1
      c.strokeRect(0.5, 0.5, size - 1, size - 1)
    })
    cachedFloorTex.wrapS = cachedFloorTex.wrapT = T.RepeatWrapping
    cachedFloorTex.repeat.set(4, 29)
  }
  return new T.MeshLambertMaterial({ map: cachedFloorTex })
}

export function brushedMaterial(color: T.ColorRepresentation) {
  if (!cachedBrushedTex) {
    cachedBrushedTex = canvas(256, 256, c => {
      c.fillStyle = '#e1e1df'
      c.fillRect(0, 0, 256, 256)
      const rnd = noise(719)
      for (let i = 0; i < 650; i++) {
        c.fillStyle = rnd() > 0.4 ? 'rgba(255,255,255,.22)' : 'rgba(23,25,23,.11)'
        c.fillRect(rnd() * 256, rnd() * 256, 4 + rnd() * 110, 0.5 + rnd() * 0.8)
      }
    })
  }
  return new T.MeshLambertMaterial({ color, map: cachedBrushedTex })
}

export function signTexture(width:number,height:number, fn:(c:CanvasRenderingContext2D)=>void) {
  return new T.MeshBasicMaterial({map:canvas(width,height,fn),toneMapped:true})
}

function ink(c:CanvasRenderingContext2D, str:string, x:number,y:number,size:number,color:string, weight=600){
  c.font=weight+' '+size+'px Arial, Helvetica, sans-serif'
  c.fillStyle=color
  c.fillText(str,x,y)
}
function dot(c:CanvasRenderingContext2D,x:number,y:number,r:number,col:string) {
  c.fillStyle=col
  c.beginPath()
  c.arc(x,y,r,0,Math.PI*2)
  c.fill()
}

export function routeMap(changed=false) {
  return signTexture(1536,200,c=>{
    c.fillStyle='#e5e3d5'
    c.fillRect(0,0,1536,200)
    c.fillStyle='#343c36'
    c.fillRect(0,0,1536,7)
    dot(c,58,67,38,'#568635')
    ink(c,'G',31,89,57,'#ffffff',800)
    ink(c,'Brooklyn–Queens Crosstown',117,48,30,'#232925',700)
    ink(c,'Court Sq–bound',117,78,20,'#4e5049',500)
    c.fillStyle='#679537'
    c.fillRect(70,123,1388,9)
    const positions=ROUTE.map((_,i)=>70+i*115.5)
    if(changed) [positions[7],positions[8]]=[positions[8],positions[7]]
    ROUTE.forEach((name,i)=>{
      const x=positions[i]
      if(i===12){
        c.shadowColor='#d6ff82'
        c.shadowBlur=12
      }
      dot(c,x,127,8,'#3c5630')
      dot(c,x,127,4,i===12?'#f1ffd2':'#d5d8c6')
      c.shadowBlur=0
      c.save()
      c.translate(x-2,152)
      for (const [j,part] of name.replaceAll('–','-').replaceAll('-','- ').split(/ (?=[A-Z])/).entries()) ink(c,part,0,j*19,16,'#282d28',600)
      c.restore()
    })
    ink(c,'New York City Subway',1261,45,22,'#31392f',600)
  })
}

export function adPoster(index:number, altered=false) {
  return signTexture(640,240,c=>{
    if(index===0){
      c.fillStyle=altered?'#aa6139':'#cfc8a5'
      c.fillRect(0,0,640,240)
      c.fillStyle='#143b35'
      c.fillRect(0,0,20,240)
      ink(c,'BROOKLYN BOTANIC GARDEN',39,35,14,'#233d31')
      ink(c,altered?'Stay a while.':'A little room',37,106,52,'#18372c',700)
      ink(c,altered?'Stay here.':'to grow.',37,163,52,'#18372c',700)
      ink(c,'EASTERN PARKWAY  /  BROOKLYN, NY',39,213,13,'#354339',600)
      const rnd=noise(2306)
      for(let j=0;j<9;j++){
        c.save()
        c.translate(465+rnd()*120,250)
        c.rotate((rnd()-.5)*1.2)
        c.strokeStyle='#52603c'
        c.lineWidth=3
        c.beginPath()
        c.moveTo(0,0)
        c.lineTo(0,-225)
        c.stroke()
        for(let k=1;k<10;k++){
          const y=-k*21
          for(const side of [-1,1]){
            c.beginPath()
            c.moveTo(0,y)
            c.quadraticCurveTo(side*23,y-10,side*28,y-39)
            c.quadraticCurveTo(side*6,y-32,0,y)
            c.fillStyle=['#305642','#4d6549','#788156'][j%3]
            c.fill()
          }
        }
        c.restore()
      }
    }else if(index===1){
      c.fillStyle='#ab4b2d'
      c.fillRect(0,0,640,240)
      c.fillStyle='#ecca86'
      c.fillRect(0,0,238,240)
      for(let j=8;j>0;j--) dot(c,120,144,j*12,j%2?'#392f26':'#ebc67f')
      ink(c,'CITY RADIO',260,65,35,'#f6dec0',800)
      ink(c,'Listen',256,135,66,'#f8e6cb',800)
      ink(c,'closely.',256,194,65,'#f8e6cb',800)
    }else if(index===2){
      c.fillStyle='#92b5ba'
      c.fillRect(0,0,640,240)
      c.fillStyle='#394e55'
      c.beginPath()
      c.moveTo(256,240)
      for(let j=0;j<17;j++){
        const x=259+j*25, h=120+Math.sin(j*21)*32
        c.lineTo(x,h)
        c.lineTo(x+19,h)
        c.lineTo(x+19,175)
      }
      c.lineTo(640,240)
      c.fill()
      ink(c,'WEEKEND WALKS',30,38,18,'#344c50')
      ink(c,'Along the',26,111,55,'#1f3a3f',700)
      ink(c,'East River.',26,167,55,'#1f3a3f',700)
      ink(c,'PARKS & RECREATION  •  CITY OF NEW YORK',30,212,13,'#2d454a')
    }else{
      c.fillStyle='#d7cebc'
      c.fillRect(0,0,640,240)
      c.fillStyle='#313b47'
      c.fillRect(0,0,160,240)
      for(let j=1;j<=7;j++){c.strokeStyle='#b4a883';c.lineWidth=2;c.beginPath();c.arc(39,125,21+j*11,0,Math.PI*2);c.stroke()}
      ink(c,'THE FALL SEASON',184,55,21,'#474e58')
      ink(c,'Chamber',178,122,56,'#2f3942',700)
      ink(c,'Music Series',181,176,48,'#2f3942',700)
      ink(c,'THURSDAY EVENINGS   /   8 PM',184,214,15,'#57534b')
    }
    c.strokeStyle='rgba(255,255,255,.3)'
    c.strokeRect(2,2,636,236)
  })
}

interface LedSignEntry {
  tex: T.CanvasTexture
  ctx: CanvasRenderingContext2D
  text: string
}

const ledRegistry: LedSignEntry[] = []

export function paintLedSign(c:CanvasRenderingContext2D, text:string){
  c.fillStyle='#14170f'
  c.fillRect(0,0,672,74)
  c.textBaseline='middle'
  c.font='900 58px Arial, sans-serif'
  c.fillStyle='#ffc060'
  c.shadowColor='#ffab40'
  c.shadowBlur=2
  const msg=text.toUpperCase()
  const w=c.measureText(msg).width
  const scale=w>0?Math.min(1,644/w):1
  c.save()
  c.translate(336,38)
  c.scale(scale,1)
  c.textAlign='center'
  c.fillText(msg,0,0)
  c.restore()
  c.shadowBlur=0
  c.fillStyle='rgba(19,19,10,.34)'
  for(let x=0;x<672;x+=4)c.fillRect(x,0,1,74)
  for(let y=0;y<74;y+=4)c.fillRect(0,y,672,1)
}

export function ledSign(text:string){
  const mat=signTexture(672,74,c=>paintLedSign(c,text))
  const tex=mat.map as T.CanvasTexture
  const ctx=(tex.image as HTMLCanvasElement).getContext('2d')!
  ledRegistry.push({tex,ctx,text})
  return mat
}

export function setLedSignText(text:string){
  for(const entry of ledRegistry){
    if(entry.text===text)continue
    paintLedSign(entry.ctx,text)
    entry.text=text
    entry.tex.needsUpdate=true
  }
}

export function label(text:string,bg:string,fg:string,width=512,height=96){
  return signTexture(width,height,c=>{
    c.fillStyle=bg
    c.fillRect(0,0,width,height)
    c.font='bold '+Math.floor(height*.65)+'px Arial'
    c.textBaseline='middle'
    c.textAlign='center'
    c.fillStyle=fg
    c.fillText(text,width/2,height*.52,width*.94)
  })
}

export function releaseMaterial(material:T.Material){
  for(const value of Object.values(material)){
    if(value instanceof T.Texture)value.dispose()
  }
  material.dispose()
}

export function glassMaterial() {
  if (!cachedGlassTex) {
    cachedGlassTex = canvas(256, 128, c => {
      const surface = c.createLinearGradient(0, 0, 0, 128)
      surface.addColorStop(0, 'rgba(177,192,176,.15)')
      surface.addColorStop(.5, 'rgba(58,76,68,.12)')
      surface.addColorStop(1, 'rgba(168,133,91,.18)')
      c.fillStyle = surface; c.fillRect(0, 0, 256, 128)
      for (const [y, w, opacity] of [[5, 4, .16], [9, 1.5, .12], [41, 2, .1], [60, 1.5, .08]]) {
        c.lineWidth = w
        c.strokeStyle = 'rgba(215,222,207,' + opacity + ')'
        c.beginPath(); c.moveTo(0, y); c.lineTo(256, y + 4.5); c.stroke()
      }
      const rnd = noise(6715)
      for (let i = 0; i < 200; i++) {
        c.fillStyle = 'rgba(201,203,183,' + (rnd() * .10) + ')'
        c.fillRect(rnd() * 256, rnd() * 128, .5 + rnd(), .5 + rnd())
      }
    })
  }
  return new T.MeshBasicMaterial({
    map: cachedGlassTex, color: '#bdc7bb', transparent: true, opacity: 0.72,
    depthWrite: false, side: T.DoubleSide,
  })
}

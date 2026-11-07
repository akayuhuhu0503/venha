import os, json, math, base64, io, re, zipfile, hashlib
from collections import defaultdict
from PIL import Image
import numpy as np
import plotly.graph_objects as go
from plotly.offline import get_plotlyjs
import trimesh
from trimesh.visual.material import PBRMaterial
from trimesh.visual.texture import TextureVisuals

ROOT=os.path.join(os.path.dirname(os.path.abspath(__file__)), '7150_ROOM3D_UPDATED_V4')
os.makedirs(ROOT,exist_ok=True)
# Real dimensions are NOT measured. All values in meters, chosen to preserve orientation.
P=[]
COL={
'floor':'#dddcd5','tile':'#eff0e9','base':'#a9b4b6','wall':'#e2dfd5','trim':'#36414c','steel':'#778690','rail':'#85919a',
'wood':'#b88858','woodlight':'#d1aa73','wooddark':'#806044','stone':'#313638','fridge':'#8b979e',
'washer':'#343840','glass':'#82adc3','water':'#519bc2','green':'#74a93a','dark':'#292f37','desk':'#353838',
'pc':'#1b2530','screen':'#3874a2','rgb':'#8d63d8','bedding':'#557797','bed':'#526575','cat':'#bdb8a8',
'plant':'#5c9251','bath':'#c5a78b','white':'#f0ebe1','gray':'#777e84','red':'#b77060'}

def box(name,g,c,s,co,yaw=0,meta=None):
    P.append({'kind':'box','name':name,'group':g,'center':[round(float(v),4) for v in c],'size':[round(float(v),4) for v in s],'color':co,'yaw':yaw,'meta':meta or name})

def cyl(name,g,c,r,h,co,axis='z',meta=None):
    P.append({'kind':'cylinder','name':name,'group':g,'center':[round(float(v),4) for v in c],'radius':r,'height':h,'axis':axis,'color':co,'meta':meta or name})

def rod(name,g,a,b,r,co,meta=None):
    P.append({'kind':'rod','name':name,'group':g,'a':list(a),'b':list(b),'radius':r,'color':co,'meta':meta or name})

# Region footprint (x left-right; y from entrance towards balcony/top; z is height)
# x main corridor 0.16..2.60, x PC alcove 2.60..5.15, y top 6.80.
box('Sàn khu cửa vào','floor',[1.145,.4,-.045],[2.95,.8,.09],COL['tile'])
box('Sàn hành lang chính','floor',[1.38,3.79,-.045],[2.44,6.02,.09],COL['tile'])
box('Sàn góc PC hình chữ L','floor',[3.875,5.55,-.045],[2.55,2.5,.09],COL['tile'])
box('Sàn nhà vệ sinh (khoang nhô)','floor',[3.075,3.12,-.055],[.95,1.3,.09],COL['bath'])
box('Sàn ban công nhỏ','floor',[1.08,7.12,-.065],[.90,.62,.10],COL['tile'])

# Low outline 0.35m; high room walls optional separate layer; missing door/window openings explicit.
def wall(name,x1,y1,x2,y2,height=2.62,base=0,col=None,group='shell_high',width=.095):
    x=(x1+x2)/2; y=(y1+y2)/2; L=math.hypot(x2-x1,y2-y1)
    yaw=math.atan2(y2-y1,x2-x1)
    box(name,group,[x,y,base+height/2],[L,width,height],col or COL['wall'],yaw)

def frame_segment(name,x1,y1,x2,y2,height=.23):
    wall(name,x1,y1,x2,y2,height=height,base=0,col=COL['trim'],group='outline',width=.11)

OUT=[(-.33,0),(2.60,0),(2.60,2.47),(3.55,2.47),(3.55,3.77),(2.60,3.77),(2.60,4.30),(5.15,4.30),(5.15,6.8),(.16,6.8),(.16,.8),(-.33,.8)]
for k,(a,b) in enumerate(zip(OUT,OUT[1:]+OUT[:1])):
    frame_segment(f'Đường bao {k+1}',*a,*b)
# High wall pieces (partially cut for doors/windows)
wall('Tường trước khu cửa',-.33,0,2.60,0)
wall('Tường hành lang bên trái',.16,.8,.16,6.8)
wall('Cạnh lõm khu cửa vào',-.33,.8,.16,.8)
wall('Tường cửa chính trên',-.33,.69,-.33,.8)
wall('Tường cửa chính dưới',-.33,0,-.33,.08)
wall('Tường hành lang bếp',2.60,0,2.60,2.47)
wall('Tường trước WC',2.60,3.55,2.60,3.77)
wall('Tường sau WC',2.60,2.47,2.60,2.62)
wall('Tường bên WC',3.55,2.47,3.55,3.77)
wall('Tường sau WC 2',2.60,3.77,2.60,4.30)
wall('Tường cạnh trong góc PC',2.60,4.30,5.15,4.30)
wall('Tường phía phải góc PC',5.15,4.30,5.15,6.80)
wall('Tường trên 1',.16,6.8,.61,6.8)
wall('Tường trên 2',1.47,6.8,3.67,6.8)
wall('Tường trên 3',4.63,6.8,5.15,6.8)
# WC smaller walls and partition
wall('Tường sau khu WC',2.60,2.47,3.55,2.47)
wall('Tường trước khu WC',2.60,3.77,3.55,3.77)
# Internal posts, visible window frame and balcony door
box('Khung cửa chính','doors',[-.31,.39,1.02],[.105,.62,2.04],COL['wooddark'])
# door has vertical orientation parallel y, swung open roughly at x=-.2
box('Cánh cửa chính gỗ','doors',[-.16,.32,1.05],[.06,.64,2.02],COL['wooddark'],yaw=-.38)
box('Khoá cửa chính','doors',[-.12,.34,1.10],[.04,.10,.25],COL['dark'])
# door balcony top wall y=6.8 x.61..1.47
box('Ngưỡng cửa ban công','doors',[1.04,6.8,.08],[.92,.11,.16],COL['trim'])
box('Khung cửa ban công bên trái','doors',[.62,6.8,1.2],[.07,.08,2.4],COL['dark'])
box('Khung cửa ban công bên phải','doors',[1.47,6.8,1.2],[.07,.08,2.4],COL['dark'])
box('Thanh trên cửa ban công','doors',[1.04,6.8,2.36],[.92,.09,.09],COL['dark'])
box('Cánh cửa ban công mở','doors',[.60,6.61,1.12],[.08,.82,2.20],COL['steel'],yaw=.45)
box('Kính cửa ban công','glass',[.65,6.59,1.24],[.022,.60,1.76],COL['glass'],yaw=.45)
# balcony railing outside
rod('Lan can ban công ngang','doors',(.65,7.43,1.07),(1.56,7.43,1.07),.025,COL['dark'])
for xx in np.linspace(.65,1.56,7): rod('Song ban công','doors',(xx,7.43,.12),(xx,7.43,1.07),.014,COL['steel'])
# Window on top wall near user's monitor, clearly left of the user when sitting facing right
box('Khung cửa sổ ngang','doors',[4.07,6.8,1.68],[.93,.075,1.06],COL['trim'])
box('Kính cửa sổ','glass',[4.07,6.8,1.68],[.82,.03,.95],COL['glass'])
for xx in (3.81,4.07,4.33):rod('Song cửa sổ dọc','doors',(xx,6.76,1.20),(xx,6.76,2.16),.012,COL['steel'])
for zz in (1.45,1.75):rod('Song cửa sổ ngang','doors',(3.69,6.755,zz),(4.50,6.755,zz),.012,COL['steel'])
# WC door opening corridor right (open into bathroom)
for yy in (2.63,3.53):box('Khung cửa WC','doors',[2.60,yy,1.10],[.08,.07,2.19],COL['trim'])
box('Cửa WC mở','doors',[2.91,2.74,1.09],[.07,.72,2.08],COL['gray'],yaw=.24)
box('Kính mờ WC','glass',[2.95,2.72,1.25],[.015,.50,1.34],COL['glass'],yaw=.24)
# Kitchen along right wall, kitchen then FRONT-LOADING washer then WC
box('Tủ dưới bếp','kitchen',[2.25,1.03,.44],[.67,1.48,.86],COL['wood'])
box('Mặt đá bếp','kitchen',[2.23,1.03,.89],[.73,1.55,.08],COL['stone'])
box('Tấm kính xanh bếp','kitchen',[2.585,1.00,1.34],[.035,1.55,.68],COL['green'])
for j in range(3):box('Cửa tủ bếp','kitchen',[1.905,.63+j*.40,.47],[.026,.37,.69],COL['woodlight'])
# sink and induction (both along kitchen) 
box('Chậu rửa inox','kitchen',[2.17,1.28,.94],[.42,.47,.05],COL['steel'])
box('Lòng chậu rửa','kitchen',[2.16,1.28,.965],[.33,.36,.018],COL['dark'])
rod('Vòi nước bếp đứng','kitchen',(2.35,1.42,.94),(2.35,1.42,1.27),.014,COL['steel'])
rod('Vòi nước bếp cong','kitchen',(2.35,1.42,1.27),(2.10,1.42,1.27),.013,COL['steel'])
box('Bếp từ kính đen','kitchen',[2.15,.69,.935],[.46,.43,.026],COL['pc'])
for yy in (.58,.80):
    cyl('Vùng đun bếp','kitchen',[2.14,yy,.952],.10,.006,COL['gray'])
# washer after kitchen on SAME wall, front-loading black with circular front
box('Máy giặt đen cửa ngang','kitchen',[2.27,2.05,.48],[.63,.70,.96],COL['washer'])
cyl('Viền cửa máy giặt','kitchen',[1.936,2.05,.48],.255,.047,COL['steel'],axis='x')
cyl('Mặt kính tròn máy giặt','kitchen',[1.901,2.05,.48],.203,.012,COL['dark'],axis='x')
box('Bảng điều khiển máy giặt','kitchen',[1.937,2.14,.85],[.022,.30,.08],COL['gray'])
# bathroom details
box('Vách gạch WC','bath',[3.49,3.12,.69],[.04,1.16,1.38],COL['bath'])
box('Bồn cầu','bath',[3.20,3.33,.30],[.32,.52,.60],COL['white'])
box('Bồn rửa WC','bath',[3.16,2.80,.82],[.30,.32,.12],COL['white'])
box('Gương WC','bath',[3.49,2.84,1.58],[.025,.42,.50],COL['glass'])
rod('Vòi sen','bath',(3.48,3.45,1.45),(3.48,3.45,2.30),.019,COL['steel'])
# Clothing rack and wardrobe on LEFT side of main passage
box('Tủ quần áo gỗ cao','storage',[.48,4.55,1.10],[.62,1.46,2.20],COL['wood'])
for yy in (4.22,4.64,5.06):box('Cánh tủ quần áo','storage',[.805,yy,1.10],[.025,.37,2.04],COL['woodlight'])
for yy in (4.28,4.95):box('Tay nắm tủ','storage',[.835,yy,1.12],[.038,.024,.24],COL['steel'])
for xx in (.25,.73):rod('Trụ giá treo đồ','storage',(xx,2.50,.02),(xx,2.50,1.68),.022,COL['steel'])
rod('Thanh ngang giá áo','storage',(.25,2.50,1.68),(.73,2.50,1.68),.028,COL['steel'])
for i,yy in enumerate((1.48,1.78,2.08,2.36,2.61)):
    box('Quần áo treo','storage',[.53,yy,1.15],[.35,.22,.85],['#414f5d','#677481','#4b5358','#7c716d','#38414a'][i])
box('Vali kéo','storage',[.46,1.16,.38],[.53,.42,.76],COL['dark'])
# small refrigerator: at corner beside Đức, facing towards north (up plan)
box('Tủ lạnh xám loại nhỏ','fridge',[2.88,4.48,.74],[.61,.46,1.48],COL['fridge'])
box('Viền cửa tủ lạnh','fridge',[2.88,4.724,.76],[.54,.027,1.38],COL['steel'])
box('Tay nắm tủ lạnh','fridge',[3.10,4.748,.87],[.025,.035,.30],COL['dark'])
cyl('Bình nước xanh trên tủ','fridge',[2.88,4.45,1.83],.22,.52,'#458cc8')
# Stairs along top wall from left of loft to landing on loft
stair_n=9
for i in range(stair_n):
    frac=(i+.5)/stair_n
    x=.99 + frac*1.58
    y=6.23 + frac*.17
    z=(i+1)*(.215)
    box(f'Bậc cầu thang {i+1}','stairs',[x,y,z],[.22,.52,.048],COL['woodlight'])
rod('Sống thang kim loại trái','stairs',(.92,5.97,.1),(2.62,6.16,2.17),.034,COL['steel'])
rod('Sống thang kim loại phải','stairs',(.92,6.52,.1),(2.62,6.69,2.17),.034,COL['steel'])
rod('Tay vịn cầu thang','stairs',(.88,5.91,.68),(2.64,6.14,2.70),.024,COL['steel'])
for i in range(5):
   a=i/4; rod('Thanh chống tay vịn','stairs',(1.0+a*1.49,5.97+a*.2,.32+a*1.67),(1.0+a*1.49,5.94+a*.2,.78+a*1.78),.011,COL['steel'])
# Loft platform over PC corner, optional hide group; deck remains at height 2.22
box('Mặt sàn gác xép','loft',[3.85,5.55,2.17],[2.56,2.50,.16],COL['base'])
box('Mặt gỗ sàn gác','loft',[3.85,5.55,2.263],[2.53,2.47,.035],COL['woodlight'])
for x in np.linspace(2.67,5.05,11):
    rod('Song lan can phía trước gác','loft_rails',(x,4.31,2.22),(x,4.31,3.18),.016,COL['steel'])
rod('Tay vịn trước gác','loft_rails',(2.65,4.31,3.2),(5.10,4.31,3.2),.032,COL['steel'])
rod('Tay vịn bên trái gác','loft_rails',(2.66,4.31,3.2),(2.66,6.60,3.2),.032,COL['steel'])
for y in np.linspace(4.32,6.6,10):rod('Song lan can bên trái gác','loft_rails',(2.66,y,2.24),(2.66,y,3.18),.014,COL['steel'])
box('Nệm và ga trên gác','sleep',[3.98,5.78,2.44],[1.68,1.54,.29],COL['bedding'])
for xx in (3.50,4.32):box('Gối trên gác','sleep',[xx,6.38,2.62],[.55,.30,.14],COL['white'])
box('Chăn trên gác','sleep',[4.02,5.28,2.62],[1.61,.61,.10],COL['bed'])
# user's PC on EAST/RIGHT wall, facing EAST (right). Window NORTH is to user's LEFT.
box('Bàn PC của tôi','user_pc',[4.76,5.82,.75],[.65,1.49,.055],COL['desk'])
for xx in (4.47,5.04):
 for yy in (5.14,6.47):box('Chân bàn PC tôi','user_pc',[xx,yy,.36],[.05,.055,.72],COL['steel'])
box('Màn hình AOC tôi','user_pc',[4.995,5.87,1.12],[.055,.63,.50],COL['dark'])
box('Mặt hình AOC tôi','user_pc',[4.955,5.87,1.12],[.014,.57,.43],COL['screen'])
box('Bàn phím trắng tôi','user_pc',[4.58,5.85,.81],[.19,.42,.045],COL['white'])
box('Pad chuột xanh tôi','user_pc',[4.58,5.40,.788],[.27,.34,.014],COL['green'])
cyl('Chuột máy tính tôi','user_pc',[4.58,5.40,.823],.048,.07,COL['white'])
box('Bể cá bên trái PC tôi','aquarium',[4.76,6.35,1.02],[.48,.40,.45],COL['water'])
box('Mặt nước bể','aquarium',[4.76,6.35,1.25],[.45,.37,.016],COL['glass'])
for ii in range(5):rod('Cây thủy sinh','aquarium',(4.64+ii*.06,6.30,.86),(4.63+ii*.06,6.34,1.12),.014,COL['plant'])
box('Đèn LED bể cá','aquarium',[4.76,6.35,1.31],[.33,.08,.06],COL['dark'])
box('Case PC RGB tôi dưới bàn','user_pc',[4.50,6.40,.30],[.44,.35,.60],COL['pc'])
for zz in (.12,.31,.49):cyl('Quạt RGB case tôi','user_pc',[4.27,6.37,zz],.09,.015,COL['rgb'],axis='x')
cyl('Ghế PC tôi','user_pc',[4.12,5.83,.48],.26,.12,COL['dark'])
box('Lưng ghế PC tôi','user_pc',[3.95,5.83,.84],[.12,.43,.69],COL['dark'])
# Đức PC faces SOUTH (toward bottom of user topdown), perpendicular to user's desk
box('Bàn PC Đức vuông góc','duc_pc',[4.17,4.62,.75],[1.43,.51,.06],COL['desk'])
for xx in (3.56,4.77):
 for yy in (4.39,4.81):box('Chân bàn PC Đức','duc_pc',[xx,yy,.35],[.05,.05,.70],COL['steel'])
box('Laptop/màn hình Đức','duc_pc',[4.08,4.36,1.08],[.58,.06,.40],COL['dark'])
box('Mặt hiển thị Đức','duc_pc',[4.08,4.398,1.08],[.53,.014,.35],COL['screen'])
box('Bàn phím và pad Đức','duc_pc',[4.08,4.70,.80],[.55,.20,.015],COL['gray'])
cyl('Ghế PC Đức','duc_pc',[4.04,5.24,.46],.26,.12,COL['dark'])
box('Lưng ghế PC Đức','duc_pc',[4.04,5.52,.82],[.50,.13,.64],COL['dark'])
box('Kệ đen góc Đức','duc_pc',[4.70,4.56,1.49],[.27,.45,1.47],COL['dark'])
# Cat area: next to wardrobe and below stairs
box('Bát ăn Bống','cat',[.84,5.72,.10],[.25,.27,.12],COL['cat'])
box('Ổ nằm Bống dưới chân thang','cat',[1.56,5.95,.12],[.56,.42,.24],COL['cat'])
# extras: a standing fan between passage/pc and fixtures
cyl('Đế quạt đứng','decor',[2.36,5.23,.055],.28,.10,COL['dark'])
rod('Thân quạt','decor',(2.36,5.23,.12),(2.36,5.23,1.25),.026,COL['steel'])
cyl('Lồng quạt','decor',[2.36,5.23,1.38],.23,.07,COL['dark'],axis='y')
box('Điều hòa trên cửa ban công','decor',[1.35,6.72,2.82],[.95,.18,.25],COL['white'])
box('Bảng ảnh trên tường PC','decor',[5.03,6.05,1.74],[.035,.75,.35],COL['wooddark'])
for yy in (5.88,6.06,6.22):box('Ảnh kỷ niệm trên bảng','decor',[5.009,yy,1.74],[.017,.11,.13],COL['white'])

# Label anchors. names map accurate positions, use fewer text markers by default.
MARKERS=[
  ('Cửa chính',[-.46,.43,1.25],'entrance','Cửa gỗ nâu nằm trong khoảng tường lõm nhỏ bên trái khi nhìn mặt bằng.'),
  ('Bếp',[2.18,1.01,1.55],'kitchen','Bếp từ và chậu rửa trên cùng một tuyến nội thất, kế tiếp là máy giặt cửa ngang.'),
  ('Máy giặt',[2.19,2.06,1.27],'kitchen','Máy giặt Casper màu đen, lồng ngang, nằm giữa bếp và cửa WC.'),
  ('WC',[3.1,3.16,1.8],'bath','WC nằm sau tường phải lối đi, dài 2,21m ra ngoài; không lấn vào hành lang.'),
  ('Giá áo',[.46,2.12,1.95],'storage','Giá treo quần áo bên trái hành lang.'),
  ('Tủ quần áo',[.45,4.58,2.4],'storage','Tủ gỗ lớn sát vách trái của lối đi.'),
  ('Ban công',[1.10,7.33,1.45],'doors','Cửa ra ban công nằm ngay phía trái cầu thang gác.'),
  ('Cầu thang',[1.8,6.23,1.77],'stairs','Bậc gỗ khung kim loại đi dọc bức tường phía trên, từ trái lên phải.'),
  ('Gác xép',[3.81,5.55,3.38],'sleep','Sàn gác phía trên hai bàn PC; có chăn, đệm, gối.'),
  ('PC của tôi',[5.03,5.91,1.57],'user_pc','Bàn áp vào tường phải; khi ngồi mặt hướng sang phải, cửa sổ ở bên trái.'),
  ('Cửa sổ',[4.06,6.82,2.31],'doors','Cửa sổ trên tường phía trên, bên trái khi ngồi vào PC của bạn.'),
  ('PC Đức',[4.13,4.50,1.47],'duc_pc','Bàn Đức vuông góc bàn bạn; khi ngồi mặt hướng xuống phía dưới sơ đồ.'),
  ('Tủ lạnh',[2.90,4.54,2.13],'fridge','Tủ lạnh nhỏ nằm bên phải Đức khi ngồi, khít góc cạnh WC, mặt trước quay lên sơ đồ.'),
  ('Bống',[1.13,5.72,.60],'cat','Ổ nằm dưới gầm cầu thang, góc ăn gần tủ gỗ/ban công.')]


# ==== 2026-11-07: measured floorplan update v3 ====
# This patch retains the photographed interior props while entirely rebuilding
# the perimeter / floor / openings from the user's dimensioned L-plan.
# 0.09 m discrepancy between side heights is distributed as ±0.045m:
# top=5.435; left step y=1.25; right notch y=2.955.
H=5.435
NOTCH=2.955
LEFT_STEP=1.25
XL=0.0
X_ENTRY=-0.47
X_COR=1.54
X_PC=3.75
# original -> resized physical meters, piecewise keeps the PC nook depth

def mx(x):
    if x<.16:
        return -.47+(x+.33)*(.47/.49)
    if x<=2.60:
        return (x-.16)*(1.54/2.44)
    return 1.54+(x-2.60)*(2.21/2.55)

def my(y):
    if y<=4.30:return y*(NOTCH/4.30)
    return NOTCH+(y-4.30)*((H-NOTCH)/2.50)

def remap_part(p):
    if p['kind']=='box':
        cx,cy,cz=p['center']; sx,sy,sz=p['size']
        nx,nY=mx(cx),my(cy)
        nsx=mx(cx+sx/2)-mx(cx-sx/2)
        nsy=my(cy+sy/2)-my(cy-sy/2)
        if p['group']=='kitchen':
            # 0.66 m inferred projection from real 1.35 m clearance.
            # Preserve kitchen/washer placement with shared front plane.
            # Update from old corridor wall x=2.60 to new x=1.54
            def kitchen_x(v):return X_COR-(2.60-v)*(.66/.74)
            nx=kitchen_x(cx)
            nsx=abs(kitchen_x(cx+sx/2)-kitchen_x(cx-sx/2))
        if p['group']=='stairs':nx+=.13
        if p['group']=='fridge':nY+=.08
        p['center']=[round(nx,4),round(nY,4),cz]
        p['size']=[round(max(.008,nsx),4),round(max(.008,nsy),4),sz]
    elif p['kind']=='cylinder':
        x,y,z=p['center']
        p['center']=[round(mx(x)+(.13 if p['group']=='stairs' else 0),4),round(my(y)+(.08 if p['group']=='fridge' else 0),4),z]
    elif p['kind']=='rod':
        p['a']=[round(mx(p['a'][0])+(.13 if p['group']=='stairs' else 0),4),round(my(p['a'][1]),4),p['a'][2]]
        p['b']=[round(mx(p['b'][0])+(.13 if p['group']=='stairs' else 0),4),round(my(p['b'][1]),4),p['b'][2]]

# Old generated shell was unconstrained by real measurements. Delete it.
# These groups are rebuilt below; furniture topology comes from real photos.
P=[p for p in P if p['group'] not in ('floor','outline','shell_high','bath','doors','glass')]
for p in P:remap_part(p)

# NEW floor footprint. Whole corridor is 1.54 m wide before kitchen; the entrance
# inset reaches 0.47 m farther left. Upper-right PC zone is 2.21 x 2.48 m.
box('01 Sàn cửa vào thụt trái','floor',[(X_ENTRY+X_COR)/2,LEFT_STEP/2,-.05],[X_COR-X_ENTRY,LEFT_STEP,.10],COL['tile'])
box('02 Sàn lối đi chính','floor',[X_COR/2,(H+LEFT_STEP)/2,-.05],[X_COR,H-LEFT_STEP,.10],COL['tile'])
box('03 Sàn hốc PC bên phải','floor',[(X_COR+X_PC)/2,(NOTCH+H)/2,-.05],[X_PC-X_COR,H-NOTCH,.10],COL['tile'])
box('04 Sàn nhà vệ sinh','floor',[(.78+X_COR)/2,(1.90+NOTCH)/2,-.04],[X_COR-.78,NOTCH-1.90,.08],COL['bath'])
box('05 Sàn ban công (tạm)','floor',[.44,H+.25,-.07],[.78,.50,.10],COL['tile'])

# Accurate L outline, no funny wall detours or invented right-side WC volume.
outline=[(X_ENTRY,0),(X_COR,0),(X_COR,NOTCH),(X_PC,NOTCH),(X_PC,H),(XL,H),(XL,LEFT_STEP),(X_ENTRY,LEFT_STEP)]
for i,(a,b) in enumerate(zip(outline,outline[1:]+outline[:1])):
    frame_segment('Tường bao ngoài — đoạn %02d'%(i+1),*a,*b)
# Add high partitions with intentional door/window openings.
wall('Tường thấp cạnh bếp',X_COR,0,X_COR,1.9)
wall('Tường phải dưới WC',X_COR,1.9,X_COR,NOTCH)
wall('Tường dưới góc PC',X_COR,NOTCH,X_PC,NOTCH)
wall('Tường phải bàn tôi',X_PC,NOTCH,X_PC,H)
wall('Tường trái lối đi chính',XL,LEFT_STEP,XL,H)
wall('Tường thụt cửa vào',XL,LEFT_STEP,X_ENTRY,LEFT_STEP)
wall('Tường dưới đáy phòng',X_ENTRY,0,X_COR,0)
wall('Tường cửa vào trên',X_ENTRY,.93,X_ENTRY,LEFT_STEP)
wall('Tường cửa vào dưới',X_ENTRY,0,X_ENTRY,.14)
# At top wall: balcony door near stairs (left), window at user's PC nook (right)
wall('Tường trên trái',0,H,.14,H)
wall('Tường giữa ban công và cửa sổ',.90,H,2.56,H)
wall('Tường trên phải',3.47,H,X_PC,H)
# WC partition front edge x~.78 (stair corridor), leave 0.69m doorway
wall('Vách WC trái đoạn đầu',.78,1.90,.78,2.05)
wall('Vách WC trái đoạn trên',.78,2.76,.78,NOTCH)
wall('Vách WC dưới',.78,1.90,X_COR,1.90)
# WC upper top is already the right-part of the PC-floor boundary (y=2.955)
# Door frames; controlled neutral geometry, editable by Codex
box('Khung cửa chính gỗ','doors',[X_ENTRY,.53,1.05],[.095,.77,2.1],COL['wooddark'])
box('Cửa chính mở','doors',[X_ENTRY+.14,.53,1.04],[.066,.73,2.05],COL['wooddark'],yaw=-.16)
box('Khóa tay cầm cửa vào','doors',[X_ENTRY+.18,.46,1.10],[.045,.10,.19],COL['dark'])
# Balcony door on top north wall, stairs immediately on the right
box('Ngưỡng ban công','doors',[.52,H,.06],[.76,.08,.12],COL['trim'])
box('Khung trái cửa ban công','doors',[.14,H,1.18],[.07,.10,2.36],COL['dark'])
box('Khung phải cửa ban công','doors',[.90,H,1.18],[.07,.10,2.36],COL['dark'])
box('Thanh trên ban công','doors',[.52,H,2.32],[.78,.08,.09],COL['dark'])
box('Cửa ban công mở vào trong','doors',[.28,H-.23,1.11],[.075,.64,2.20],COL['steel'],yaw=.48)
box('Kính cửa ban công','glass',[.30,H-.23,1.11],[.025,.53,1.75],COL['glass'],yaw=.48)
rod('Thanh lan can ban công','doors',(.10,H+.50,1.05),(.86,H+.50,1.05),.022,COL['dark'])
for q in np.linspace(.10,.86,6):rod('Song lan can ban công','doors',(q,H+.5,.18),(q,H+.5,1.05),.012,COL['steel'])
# A distinct window located on the north wall, LEFT of user when seated at right-facing PC
box('Khung cửa sổ bên trái bàn của tôi','doors',[3.02,H,1.65],[.91,.075,1.08],COL['trim'])
box('Kính cửa sổ đúng vị trí','glass',[3.02,H,1.65],[.83,.027,.98],COL['glass'])
for q in (2.78,3.02,3.26):rod('Chấn song cửa sổ','doors',(q,H-.07,1.16),(q,H-.07,2.16),.014,COL['steel'])
for z in (1.43,1.74):rod('Thanh ngang cửa sổ','doors',(2.62,H-.07,z),(3.42,H-.07,z),.012,COL['steel'])
# WC door facing aisle, smaller than full-height bath wall
for q in (2.06,2.75):box('Khung cửa WC màu xám','doors',[.785,q,1.06],[.085,.075,2.12],COL['trim'])
box('Cửa WC mở vào trong','doors',[.95,2.25,1.05],[.05,.55,2.05],COL['gray'],yaw=.33)
box('Kính mờ WC','glass',[.93,2.25,1.22],[.016,.43,1.38],COL['glass'],yaw=.33)
# photographed WC details, not exterior protrusion
box('Gạch ốp nhà vệ sinh','bath',[1.51,2.43,.73],[.028,.92,1.46],COL['bath'])
box('Bồn cầu','bath',[1.31,2.60,.35],[.28,.34,.60],COL['white'])
box('Bồn rửa WC','bath',[1.30,2.13,.76],[.30,.25,.12],COL['white'])
box('Gương WC','bath',[1.51,2.16,1.49],[.020,.39,.51],COL['glass'])
rod('Ống vòi sen','bath',(1.50,2.70,1.45),(1.50,2.70,2.20),.018,COL['steel'])

# Text labels show calculated values without asserting they were all measured.
newmarkers=[]
for name,pt,g,desc in MARKERS:
    if g=='bath':
        pt=[.99,2.38,1.60]
    elif name.startswith('Cửa chính'):
        pt=[-.55,.53,1.35]
    elif name.startswith('Ban công'):
        pt=[.48,H+.5,1.4]
    elif name.startswith('Cửa sổ'):
        pt=[3.03,H,2.33]
    elif g=='kitchen':
        pt=[1.18,my(pt[1]),pt[2]]
    else:
        pt=[mx(pt[0]) + (.13 if g=='stairs' else 0), my(pt[1]) + (.08 if g=='fridge' else 0), pt[2]]
    newmarkers.append((name,pt,g,desc))
MARKERS=newmarkers
# Use a structured scale record with provenance; do not treat all values as verified.
DIMS={
    'top_width':3.75,'total_depth_model':H,'upper_right_height':2.48,
    'recess_width':2.21,'inner_right_height_model':NOTCH,
    'left_main_height_model':H-LEFT_STEP,
    'left_entrance_segment':LEFT_STEP,'entrance_offset':.47,
    'lower_outer_width_derived':2.01,'clearance_to_kitchen_measured':1.35,
    'kitchen_projection_derived':.66,
    'vertical_discrepancy_original':.09,
    'loft_height_placeholder':2.17
}
# ==== end measured v3 patch ====

# ===== v4 CORRECTIONS: bathroom and human-scale passage =====
# User update: toilet/WC begins at the right corridor wall. It does NOT protrude
# into the walkway. The WC is approximately 2.21 metres in depth from that wall;
# the span parallel to the corridor is a provisional 1.18m, not a user measurement.
# It is an auxiliary/service footprint in the LOWER-RIGHT L-plan recess, rather
# than a furniture box inside the corridor. Preserve the user's measured main L.
BATH_DEPTH=2.21
BATH_Y_MAX=NOTCH
BATH_Y_MIN=BATH_Y_MAX - 1.18 # width NOT confirmed by user
WC_X0=X_COR
WC_X1=WC_X0+BATH_DEPTH
# Remove incorrect bathroom occupying passage from x=.78..1.54, and its walls.
P=[p for p in P if not (
    p['group']=='bath'
    or (p['group']=='floor' and 'nhà vệ sinh' in p['name'])
    or (p['group']=='shell_high' and p['name'] in [
      'Tường phải dưới WC','Vách WC trái đoạn đầu','Vách WC trái đoạn trên','Vách WC dưới'
    ])
    or ((p['group']=='doors' or p['group']=='glass') and ('WC' in p['name']))
)]
# Service alcove to the right of the true corridor. Main L perimeter stays visible.
box('Sàn WC nằm SAU vách hành lang','floor',[(WC_X0+WC_X1)/2,(BATH_Y_MIN+BATH_Y_MAX)/2,-.041],
    [BATH_DEPTH,BATH_Y_MAX-BATH_Y_MIN,.082],COL['bath'])
# Low bathroom outline. Shared upper wall with PC nook is already in main L.
frame_segment('WC tường ngoài phải',WC_X1,BATH_Y_MIN,WC_X1,BATH_Y_MAX)
frame_segment('WC tường ngoài dưới',WC_X0,BATH_Y_MIN,WC_X1,BATH_Y_MIN)
# The entrance to WC is a gap in the corridor wall; not a partition protruding left.
DOOR_Y_BOTTOM=2.02
DOOR_Y_TOP=2.72
wall('Vách ngoài WC cạnh hành lang dưới',WC_X0,1.90,WC_X0,DOOR_Y_BOTTOM)
wall('Vách ngoài WC cạnh hành lang trên',WC_X0,DOOR_Y_TOP,WC_X0,BATH_Y_MAX)
wall('Vách ngoài WC phía sau',WC_X1,BATH_Y_MIN,WC_X1,BATH_Y_MAX)
wall('Vách ngoài WC phía dưới',WC_X0,BATH_Y_MIN,WC_X1,BATH_Y_MIN)
# WC front top edge is already 'Tường dưới góc PC' from main L plot.
for yy in [DOOR_Y_BOTTOM,DOOR_Y_TOP]:
    box('Khung cửa WC sát tường hành lang','doors',[WC_X0,yy,1.055],[.078,.067,2.11],COL['trim'])
box('Cánh cửa WC hướng vào trong','doors',[WC_X0+.25,2.27,1.035],[.050,.63,2.07],COL['gray'],yaw=.29)
box('Kính mờ cánh WC','glass',[WC_X0+.27,2.27,1.21],[.018,.46,1.43],COL['glass'],yaw=.29)
# Bathroom interior, 2.21m deep from corridor wall x1.54 to far wall x3.75.
box('Bồn rửa WC thật nằm sau vách','bath',[WC_X0+.52,BATH_Y_MIN+.30,.80],[.41,.30,.14],COL['white'])
box('Gương WC','bath',[WC_X0+.52,BATH_Y_MIN+.04,1.51],[.40,.02,.49],COL['glass'])
box('Bồn cầu WC','bath',[WC_X0+1.16,BATH_Y_MAX-.30,.38],[.42,.42,.68],COL['white'])
rod('Vòi sen WC','bath',(WC_X1-.13,BATH_Y_MAX-.22,1.18),(WC_X1-.13,BATH_Y_MAX-.22,2.22),.019,COL['steel'])
box('Vách gạch sẫm WC','bath',[WC_X1-.025,(BATH_Y_MIN+BATH_Y_MAX)/2,.75],[.03,BATH_Y_MAX-BATH_Y_MIN,.92],COL['bath'])
# Clear the wardrobe side of the main walkway, without falsifying large furniture dimensions.
# Center of clothes rack is farther inside than washing machine in real pictures.
for p in P:
  if p['group']=='storage' and ('Quần áo treo' in p['name'] or 'giá treo' in p['name'].lower()):
    if p['kind']=='box':p['center'][1]=round(p['center'][1]+.22,4)
    elif p['kind']=='rod':
      p['a'][1]=round(p['a'][1]+.22,4);p['b'][1]=round(p['b'][1]+.22,4)
# New WC marker
MARKERS=[m if m[0]!='WC' else ('WC 2,21 m',[2.55,2.42,1.75],'bath',
  'Nhà vệ sinh mở từ vách phải của hành lang; chiều sâu ra phía phải 2,21 m, không nhô vào lối đi. Bề ngang còn ước lượng.') for m in MARKERS]
# Update scale & provenance. The kitchen-side clear width at entrance is 1.35m USER MEASURED.
DIMS.update({
   'bathroom_depth_from_corridor_wall_m':BATH_DEPTH,
   'bathroom_width_parallel_corridor_placeholder_m':round(BATH_Y_MAX-BATH_Y_MIN,2),
   'main_corridor_width_between_walls_m':X_COR,
   'entrance_clear_to_kitchen_front_user_measured_m':1.35,
   'wc_intrusion_into_corridor_m':0.0,
   'previous_error_wc_intruded_into_corridor_m':0.76,
   'bathroom_caveat':'2.21 m interpreted as room depth measured perpendicular to main corridor; bathroom width provisional. Service annex lies outside measured main L footprint.'
})
# ===== END v4 =====

# conversion plotly mesh primitives
FACES=[(0,1,2,3),(4,7,6,5),(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)]
def rgb(hexs):return tuple(int(hexs[i:i+2],16) for i in (1,3,5))
def shade(c,fac):return f'rgb({min(255,int(rgb(c)[0]*fac))},{min(255,int(rgb(c)[1]*fac))},{min(255,int(rgb(c)[2]*fac))})'
def box_mesh(p):
    cx,cy,cz=p['center']; sx,sy,sz=p['size']; yaw=p['yaw']
    vx=np.array([[-1,-1,-1],[1,-1,-1],[1,1,-1],[-1,1,-1],[-1,-1,1],[1,-1,1],[1,1,1],[-1,1,1]],float) * np.array([sx,sy,sz])/2
    R=np.array([[math.cos(yaw),-math.sin(yaw),0],[math.sin(yaw),math.cos(yaw),0],[0,0,1]])
    vx=vx@R.T+np.array([cx,cy,cz]); tri=[]; facecol=[]
    for fi,quad in enumerate(FACES):
        for face in ((quad[0],quad[1],quad[2]),(quad[0],quad[2],quad[3])):
            tri.append(face);facecol.append(shade(p['color'],[.78,.90,.98,1.03,.89,1.06][fi]))
    return vx.tolist(),tri,facecol

def cyl_mesh(p, count=12):
    if p['kind']=='rod':
        a=np.array(p['a'],dtype=float);b=np.array(p['b'],dtype=float); c=(a+b)/2;axis=b-a; h=np.linalg.norm(axis);r=p['radius'];axis=axis/(h if h else 1)
    else:
        c=np.array(p['center'],dtype=float);h=p['height'];r=p['radius'];axis={'z':np.array([0.,0.,1.]),'x':np.array([1.,0.,0.]),'y':np.array([0.,1.,0.])}[p.get('axis','z')]
    aux=np.array([0.,0.,1.]) if abs(axis[2])<.9 else np.array([1.,0.,0.]);u=np.cross(axis,aux);u=u/np.linalg.norm(u);v=np.cross(axis,u)
    pts=[]
    for height in (-h/2,h/2):
      for i in range(count):
        theta=i/count*math.tau
        pts.append((c + axis*height+r*(math.cos(theta)*u+math.sin(theta)*v)).tolist())
    faces=[]; cols=[]
    for i in range(count):
       q=(i+1)%count;faces.extend([(i,q,count+q),(i,count+q,count+i)]);cols.extend([shade(p['color'],.89+.14*math.cos(i/count*math.tau))]*2)
    for i in range(1,count-1):faces.extend([(0,i+1,i),(count,count+i,count+i+1)]); cols.extend([shade(p['color'],.95),shade(p['color'],1.05)])
    return pts,faces,cols

M=defaultdict(lambda:{'verts':[],'tri':[],'cols':[]})
for part in P:
    pts,faces,colors=box_mesh(part) if part['kind']=='box' else cyl_mesh(part)
    group=part['group']; cur=M[group]; idx=len(cur['verts']); cur['verts'].extend(pts);cur['tri'].extend([[x+idx for x in face] for face in faces]);cur['cols'].extend(colors)

# mesh groups named for dynamic layer visibility
GROUP_INFO=[('floor','Sàn gạch','visible'),('outline','Đường bao thực','visible'),('shell_high','Tường cao','legendonly'),('doors','Cửa / khung','visible'),('glass','Kính','visible'),('kitchen','Bếp và máy giặt','visible'),('bath','Nhà vệ sinh','visible'),('storage','Tủ và giá áo','visible'),('fridge','Tủ lạnh','visible'),('stairs','Cầu thang','visible'),('loft','Sàn gác','visible'),('loft_rails','Lan can gác','visible'),('sleep','Khu ngủ trên gác','visible'),('user_pc','PC của bạn','visible'),('duc_pc','PC của Đức','visible'),('aquarium','Bể cá','visible'),('cat','Khu vực Bống','visible'),('decor','Đồ sinh hoạt','visible')]
FIG=go.Figure(); GROUP_TRACES=defaultdict(list)
for group,name,vis in GROUP_INFO:
    a=M[group];xyz=np.array(a['verts']);tri=np.array(a['tri'])
    opacity=0.55 if group=='glass' else (0.62 if group=='loft' else 1)
    if group=='shell_high':opacity=.55
    FIG.add_trace(go.Mesh3d(x=xyz[:,0],y=xyz[:,1],z=xyz[:,2],i=tri[:,0],j=tri[:,1],k=tri[:,2],facecolor=a['cols'],
     name=name,legendgroup=group,showlegend=False,hoverinfo='skip',flatshading=True,opacity=opacity,
     lighting=dict(ambient=.69,diffuse=.7,specular=.24,roughness=.58,fresnel=.08),lightposition=dict(x=1,y=4,z=15),
     visible=(vis=='visible')))
    GROUP_TRACES[group].append(len(FIG.data)-1)
# outline floor tile stripes clipped by rectangles for a recognizably real tile floor
lines=[]
rects=[(X_ENTRY,X_COR,0,LEFT_STEP),(XL,X_COR,LEFT_STEP,H),(X_COR,X_PC,NOTCH,H)]
for xl,xr,yb,yt in rects:
    for xx in np.arange(math.ceil(xl/.55)*.55,xr,.55):lines +=[((xx,yb,.01),(xx,yt,.01))]
    for yy in np.arange(math.ceil(yb/.55)*.55,yt,.55):lines +=[((xl,yy,.01),(xr,yy,.01))]
xs=[];ys=[];zs=[]
for a,b in lines:xs.extend([a[0],b[0],None]);ys.extend([a[1],b[1],None]);zs.extend([a[2],b[2],None])
FIG.add_trace(go.Scatter3d(x=xs,y=ys,z=zs,mode='lines',line=dict(color='rgba(85,101,110,.2)',width=2),showlegend=False,hoverinfo='skip',name='Mạch gạch'))
GROUP_TRACES['floor'].append(len(FIG.data)-1)
# highlighted location markers
FIG.add_trace(go.Scatter3d(x=[p[1][0] for p in MARKERS],y=[p[1][1] for p in MARKERS],z=[p[1][2] for p in MARKERS],
    mode='markers+text',text=[p[0] for p in MARKERS],textposition='top center',textfont=dict(color='#152e39',size=11),
    marker=dict(size=4,color='#ffd487',line=dict(color='#fff',width=1)),customdata=[p[3] for p in MARKERS],
    hovertemplate='<b>%{text}</b><br>%{customdata}<extra></extra>',showlegend=False,name='Chú thích'))
GROUP_TRACES['labels'].append(len(FIG.data)-1)
# reference to camera coordinates before rotate 
FIG.update_layout(scene=dict(aspectmode='data',xaxis=dict(visible=False,range=[-.85,4.05]),yaxis=dict(visible=False,range=[-.45,6.1]),zaxis=dict(visible=False,range=[0,3.7]),
    camera=dict(eye=dict(x=1.62,y=-1.72,z=1.77),center=dict(x=0,y=0,z=-.12),up=dict(x=0,y=0,z=1)),
    bgcolor='rgba(0,0,0,0)',dragmode='orbit'),
    paper_bgcolor='rgba(0,0,0,0)',plot_bgcolor='rgba(0,0,0,0)',margin=dict(l=0,r=0,t=0,b=0),
    showlegend=False,hovermode='closest',uirevision='layout-v4-wc-clearance')

# export GLB based on exact same primitive list
scene=trimesh.Scene()
for idx,p in enumerate(P):
    if p['kind']=='box':
       geom=trimesh.creation.box(extents=p['size']);T=trimesh.transformations.rotation_matrix(p['yaw'],[0,0,1]);T[:3,3]=p['center']
    else:
       if p['kind']=='rod':
          a=np.array(p['a']);b=np.array(p['b']); direction=b-a;h=np.linalg.norm(direction);geom=trimesh.creation.cylinder(radius=p['radius'],height=h,sections=12)
          T=trimesh.geometry.align_vectors([0,0,1],direction / h);T[:3,3]=(a+b)/2
       else:
          geom=trimesh.creation.cylinder(radius=p['radius'],height=p['height'],sections=12)
          T=trimesh.geometry.align_vectors([0,0,1],{'z':[0,0,1],'x':[1,0,0],'y':[0,1,0]}[p.get('axis','z')]);T[:3,3]=p['center']
    rgbc=rgb(p['color'])
    geom.visual=TextureVisuals(material=PBRMaterial(baseColorFactor=np.array([*rgbc,255],dtype=np.uint8),roughnessFactor=.75,metallicFactor=.1))
    # glTF/Godot is Y-up: map HTML/source x,y(depth),z(height) -> x,z(height),-y(depth).
    T=trimesh.transformations.rotation_matrix(-math.pi/2,[1,0,0]) @ T
    scene.add_geometry(geom,geom_name=f'{idx:03d}_{p["group"]}_{re.sub("[^a-z0-9]+","_",p["name"].lower())[:14]}',node_name=f'{idx:03d}_{p["group"]}',transform=T)
with open(os.path.join(ROOT,'7150_PHONG_TRO_LAYOUT_v4.glb'),'wb') as f: f.write(scene.export(file_type='glb'))

with open(os.path.join(ROOT,'7150_ROOM_LAYOUT_SOURCE.json'),'w',encoding='utf8') as f:
    json.dump(dict(metadata={'dimensions_m':DIMS,'title':'7:50 — VỀ NHÀ | Measured Room Spatial Blockout v4',
         'units':'meters; measurements approximate, some geometry inferred',
         'reference_priority':['latest user hand-drawn floorplan','IMG_0907 to IMG_0915 actual room photos','video of actual empty room'],
         'axes':'x: left-to-right on plan; y: entry-to-balcony/top on plan; z: height',
         'critical':['Entrance inset LEFT wall near bottom, not lower middle','Kitchen -> front-loading washer -> WC on RIGHT corridor wall','Wardrobe and clothes rack on LEFT passage','Balcony door LEFT of stairs on upper wall','PC area branches RIGHT at far end','User PC faces RIGHT wall (+x), window on upper wall to seated LEFT','Duc PC faces DOWN (-y), perpendicular to user PC','Small fridge beside Duc at WC corner, faces UP (+y)','Loft directly above both PC areas'],
         'uncertain':'Footprint approx. WC depth 2.21m from corridor wall, extends RIGHT into service annex; width unknown. Kitchen clearance measured 1.35m and projection derived 0.66m; loft height provisional.'},parts=P,markers=MARKERS),f,ensure_ascii=False,indent=2)

# small JPEG photos embedded (true photos)
photos=[('1 · Vừa vào / khu bếp','IMG_0908.jpeg'),('2 · Cửa chính','IMG_0907.jpeg'),('3 · Lối đi','IMG_0909.jpeg'),('4 · Cửa WC','IMG_0910.jpeg'),('5 · Tủ / cầu thang','IMG_0911(1).jpeg'),('6 · Rẽ phải khu PC','IMG_0912.jpeg'),('7 · PC của bạn','IMG_0914.jpeg'),('8 · PC của Đức','IMG_0915.jpeg'),('9 · Ban công + cầu thang','IMG_0913.jpeg')]
photo_html=[]
for title,file in photos:
    im=Image.open(os.path.join(ROOT,'reference',file) if os.path.exists(os.path.join(ROOT,'reference',file)) else '/mnt/data/'+file).convert('RGB'); im.thumbnail((530,530),Image.Resampling.LANCZOS);out=io.BytesIO();im.save(out,format='JPEG',quality=68,optimize=True)
    photo_html.append(dict(title=title,data='data:image/jpeg;base64,'+base64.b64encode(out.getvalue()).decode()))

layout_json=FIG.to_json()
group_json=json.dumps(GROUP_TRACES,ensure_ascii=False)
photo_json=json.dumps(photo_html,ensure_ascii=False)
marker_json=json.dumps(MARKERS,ensure_ascii=False)
mesh_json=json.dumps({k:v for k,v in M.items()},ensure_ascii=False,separators=(',',':'))
grid_json=json.dumps(lines,separators=(',',':'))
prim_json=json.dumps(P,ensure_ascii=False,separators=(',',':'))
# html with local plotly script embedded so one file works fully offline
head=r'''<!doctype html><html lang="vi"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>7:50 — PHÒNG TRỌ 3D TƯƠNG TÁC</title>
<style>
*{box-sizing:border-box}html,body{height:100%;margin:0;font-family:Inter,"Segoe UI",Arial,sans-serif;color:#e5eef6;background:#0d1620}body{overflow:hidden}
nav{height:67px;background:#111e2b;border-bottom:1px solid #2d4254;display:flex;align-items:center;justify-content:space-between;padding:0 22px;gap:15px;position:relative;z-index:2}.logo{font-weight:800;letter-spacing:.3px;font-size:17px}.logo span{color:#f0d29b}.muted{font-size:11px;color:#a1b1c1;display:block;padding-top:2px}.pill{font-size:11px;border:1px solid #43576a;border-radius:40px;padding:7px 10px;color:#b4cadb;background:#1b2b38}
main{height:calc(100% - 67px);display:grid;grid-template-columns:285px minmax(400px,1fr) 245px;min-width:800px}.panel{background:#111d29;overflow-y:auto;padding:19px 16px;border-right:1px solid #2d4254}.right{border-left:1px solid #2d4254;border-right:0}.subhead{font-size:10px;letter-spacing:1.5px;text-transform:uppercase;color:#82a7c5;font-weight:800;margin:16px 0 9px}h2{margin:0;font-size:18px}p{font-size:13px;line-height:1.55;color:#bdcbd7}.seg{display:grid;grid-template-columns:1fr 1fr;gap:7px}button{font-family:inherit;color:#dceaf5;background:#22384b;border:1px solid #38536a;border-radius:8px;padding:9px 11px;cursor:pointer;text-align:left;font-size:12px}button:hover{background:#31536d}button.active{background:#285a72;border-color:#6fc9e4;color:white}.stack{display:flex;flex-direction:column;gap:7px}.switch{display:flex;align-items:center;gap:9px;border-bottom:1px solid #223344;padding:10px 0;color:#cbd8e5;font-size:13px}.switch input{accent-color:#6dc7e5;width:16px;height:16px}.guide{margin-top:12px;border:1px solid #30465b;background:#172839;border-radius:10px;padding:12px;font-size:12px;line-height:1.6;color:#c1d0dc}.guide b{color:#f2d39e}.view{position:relative;overflow:hidden;background:radial-gradient(ellipse at center,#f2efe8 0%,#d0d7d6 60%,#9daeb1 100%)}#view3d{position:absolute;inset:0;width:100%;height:100%}.bottom-note{position:absolute;bottom:17px;left:16px;right:16px;pointer-events:none;display:flex;gap:12px;justify-content:space-between;align-items:end;z-index:1}.bottom-note>div{color:#cee5ed;font-size:11px;background:rgba(16,35,50,.84);padding:9px 12px;border-radius:7px;line-height:1.5;backdrop-filter:blur(8px)}.photo{width:100%;border:1px solid #30465b;border-radius:10px;object-fit:cover;max-height:230px;background:#222}.refbar{display:grid;grid-template-columns:repeat(3,1fr);gap:5px;margin-top:10px}.refbar button{padding:6px;text-align:center}.desc{font-size:12px;color:#b4c4d2;margin-top:10px;line-height:1.5}.info-card{border:1px solid #334b60;background:#17283a;border-radius:10px;padding:12px;margin:12px 0}.info-card h3{color:#f1d49e;margin:0 0 8px;font-size:13px}.info-card p{margin:0}.rule{color:#8ca3b6;font-size:12px;line-height:1.5}.hotkeys{font-size:12px;line-height:1.8}.hotkeys kbd{display:inline-block;background:#243647;border:1px solid #3a556b;border-radius:4px;padding:1px 6px;font-size:11px;margin-right:5px;color:#fff}
@media(max-width:1060px){main{grid-template-columns:230px minmax(400px,1fr)}.right{display:none}}
@media(max-width:700px){body{overflow:auto}nav{height:auto;min-height:70px;padding:10px}.pill{display:none}main{height:auto;display:flex;flex-direction:column;min-width:0}.panel{order:2;max-height:none}.view{order:1;height:65vh;min-height:440px}.right{display:block;order:3}.bottom-note{display:none}}
</style></head><body><nav><div><div class="logo"><span>7:50</span> / VỀ NHÀ — PHÒNG TRỌ 3D</div><span class="muted">3D xoay tự do · Đường bao theo sơ đồ 07/11 · bếp sâu ~0,66 m · WC dài 2,21 m</span></div><div class="pill">v4 · WC không lấn hành lang · kích thước ước lượng</div></nav><main><aside class="panel"><h2>Góc nhìn</h2><p>Chọn góc camera, rồi kéo chuột để xoay toàn bộ căn phòng.</p><div class="seg" id="views"><button data-view="overview" class="active">◈ Toàn cảnh 3D</button><button data-view="top">▦ Mặt bằng</button><button data-view="pc">▣ Góc PC</button><button data-view="corridor">⇢ Lối đi</button><button data-view="entrance">⌂ Từ cửa</button><button data-view="loft">⬈ Gác xép</button></div>
<div class="subhead">Hiện / ẩn cấu trúc</div><div class="stack" id="toggles"><label class="switch"><input type="checkbox" id="loftT" checked> Gác xép và chăn đệm</label><label class="switch"><input type="checkbox" id="wallT"> Tường cao</label><label class="switch"><input type="checkbox" id="labelT" checked> Tên đồ vật</label><label class="switch"><input type="checkbox" id="furnT" checked> Nội thất</label></div>
<div class="guide"><b>Cách điều khiển</b><br>• Kéo chuột trái: xoay 3D<br>• Lăn chuột: phóng to / thu nhỏ<br>• Chuột phải: kéo dịch góc nhìn<br>• Nhấn vào điểm chú thích: xem mô tả<br><br><b>Quan trọng:</b> tất cả các góc đều lấy từ <i>cùng một mô hình thật</i>, không phải 6 ảnh AI độc lập.</div>
<div class="subhead">Căn cứ dựng</div><p class="rule">Ảnh phòng hiện tại: IMG_0907–0915. Cửa chính ở đoạn tường lõm <b>bên trái</b>; ban công ở cuối hành lang; khu PC mở sang phải; gác nằm trên đầu hai máy.</p></aside><section class="view"><div id="view3d"></div><div class="bottom-note"><div><b>GIỮ NGUYÊN HƯỚNG:</b> Bàn bạn nhìn sang <b>phải</b>; bàn Đức nhìn xuống mặt bằng.<br>Tủ lạnh nhỏ cạnh Đức · cửa sổ bên trái bạn · gác ngay phía trên.</div><div>WC sâu 2,21m (theo bạn)<br>Bếp chừa 1,35m (đã đo) · GLB cùng dữ liệu</div></div></section>
<aside class="panel right"><h2>Đối chiếu ảnh thật</h2><p>Chọn ảnh để so với bố cục 3D khi bạn xoay.</p><img class="photo" id="photo"><div class="desc" id="photoLabel"></div><div class="refbar" id="refs"></div><div class="subhead">Vật thể được chọn</div><div class="info-card" id="objectInfo"><h3>Hãy bấm vào nhãn 3D</h3><p>Thông tin vị trí sẽ hiện ở đây.</p></div><div class="subhead">Lưu ý đo đạc</div><p class="rule">Sàn / đồ nội thất mới ở tỉ lệ phỏng đoán. Mọi vị trí có thể được Codex chỉnh trong file <code>7150_ROOM_LAYOUT_SOURCE.json</code> — không nên dùng số đo như bản vẽ thi công.</p><div class="subhead">Sử dụng cho Codex</div><p class="rule">Import <b>7150_PHONG_TRO_LAYOUT_v4.glb</b> vào Godot, giữ nguyên tọa độ nội thất; không sắp xếp lại bàn hoặc cầu thang từ hình tham khảo 2D.</p></aside></main>
<script>
'''
body=r'''
const F = __FIG__; const GT = __GROUP__; const PH = __PHOTOS__;
const MESHES = __MESHES__; const MARKERS=__MARKERS__;
const gd=document.getElementById('view3d');
const config={responsive:true,scrollZoom:true,displaylogo:false,modeBarButtonsToRemove:['lasso2d','select2d','hoverClosest3d','resetCameraLastSave3d']};
let usingFallback=false; let canvas=null,ctx=null,cam=null;
try{usingFallback=!(document.createElement('canvas').getContext('webgl')||document.createElement('canvas').getContext('experimental-webgl'));}catch(e){usingFallback=true}
if(!usingFallback){Plotly.newPlot(gd,F.data,F.layout,config).then(()=>{gd.on('plotly_click',e=>{const d=e.points?.[0];if(d&&d.data?.name==='Chú thích'){const name=d.text, info=d.customdata;document.querySelector('#objectInfo').innerHTML='<h3>'+name+'</h3><p>'+info+'</p>';}})});}else{queueMicrotask(initCanvasFallback)}

const presets={overview:{x:1.67,y:-1.70,z:1.63},top:{x:0.01,y:0.01,z:3.30},pc:{x:-1.60,y:-1.30,z:.83},corridor:{x:-1.65,y:-1.40,z:.93},entrance:{x:.17,y:-2.35,z:.88},loft:{x:1.5,y:.68,z:2.1}};
function setPreset(name){const eye=presets[name];if(usingFallback){fallbackPreset(name)}else{let eye2=(name==='top'?{x:0,y:-0.001,z:3.2}:eye);let up2=(name==='top'?{x:0,y:1,z:0}:{x:0,y:0,z:1});Plotly.relayout(gd,{'scene.camera.eye':eye2,'scene.camera.center':{x:0,y:0,z:0},'scene.camera.up':up2});}document.querySelectorAll('#views button').forEach(b=>b.classList.toggle('active',b.dataset.view===name));if(name==='top'){document.getElementById('loftT').checked=false;applyLayers()}}
document.querySelectorAll('#views button').forEach(b=>b.addEventListener('click',()=>setPreset(b.dataset.view)));
function showLayer(name,flag){if(usingFallback){if(flag)hidden.delete(name);else hidden.add(name);renderFallback();return;}let ids=GT[name]||[];if(ids.length)Plotly.restyle(gd,{visible:flag},ids)}
function applyLayers(){let loft=document.querySelector('#loftT').checked,full=document.querySelector('#wallT').checked,labels=document.querySelector('#labelT').checked,furn=document.querySelector('#furnT').checked;for(let group of ['loft','loft_rails','sleep'])showLayer(group,loft);showLayer('shell_high',full);showLayer('labels',labels);for(let group of ['kitchen','bath','storage','fridge','user_pc','duc_pc','aquarium','cat','decor'])showLayer(group,furn)}
for(let id of ['loftT','wallT','labelT','furnT'])document.getElementById(id).addEventListener('change',applyLayers);
function photoAt(i){const p=PH[i];document.getElementById('photo').src=p.data;document.getElementById('photoLabel').innerText=p.title;document.querySelectorAll('#refs button').forEach((b,j)=>b.classList.toggle('active',i===j))}
const refs=document.getElementById('refs');PH.forEach((p,i)=>{const b=document.createElement('button');b.textContent=String(i+1).padStart(2,'0');b.title=p.title;b.onclick=()=>photoAt(i);refs.appendChild(b)});photoAt(5);
window.addEventListener('resize',()=>{if(usingFallback)resizeFallback();else Plotly.Plots.resize(gd)});
// Pure Canvas 2D 3D renderer: rotated projection fallback if WebGL is unavailable.
// The canvas uses the exact same triangle mesh as the GLB and WebGL viewer.
const hidden=new Set(['shell_high']);
const v3=(a,b)=>a.map((v,i)=>v-b[i]);
const dot=(a,b)=>a[0]*b[0]+a[1]*b[1]+a[2]*b[2];
const cross=(a,b)=>[a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]];
const unit=a=>{const n=Math.hypot(...a);return a.map(v=>v/n)};
function fallbackPreset(name){
 const views={overview:{yaw:-.79,pitch:.64,radius:11,target:[1.62,2.7,1.0]},top:{yaw:-1.570796,pitch:1.56,radius:11.2,target:[1.63,2.7,.3]},pc:{yaw:-2.34,pitch:.47,radius:6.0,target:[3.04,4.2,1.0]},corridor:{yaw:-1.5,pitch:.32,radius:9,target:[.75,2.7,1.2]},entrance:{yaw:-1.59,pitch:.24,radius:10,target:[.67,1.6,1.1]},loft:{yaw:-.4,pitch:.48,radius:5.8,target:[2.70,4.10,2.45]}};
 cam={...views[name]};renderFallback();
}
function initCanvasFallback(){
 gd.innerHTML='<canvas id="rotating3d" title="Kéo chuột để xoay mô hình 3D"></canvas>';
 canvas=document.querySelector('#rotating3d');canvas.style.cssText='width:100%;height:100%;display:block;cursor:grab;touch-action:none';ctx=canvas.getContext('2d');
 fallbackPreset('overview');resizeFallback();
 let dragging=false,previous=null,button=0;
 canvas.addEventListener('contextmenu',e=>e.preventDefault());
 canvas.addEventListener('pointerdown',e=>{canvas.setPointerCapture(e.pointerId);dragging=true;previous=[e.clientX,e.clientY];button=e.button;canvas.style.cursor='grabbing'});
 canvas.addEventListener('pointerup',()=>{dragging=false;canvas.style.cursor='grab'});
 canvas.addEventListener('pointermove',e=>{
  if(!dragging)return; const dx=e.clientX-previous[0],dy=e.clientY-previous[1];previous=[e.clientX,e.clientY];
  if(button===2 || e.shiftKey){cam.target[0]-=dx*.009;cam.target[1]+=dy*.009}else{cam.yaw-=dx*.008;cam.pitch=Math.max(-.12,Math.min(1.56,cam.pitch+dy*.007))}renderFallback()});
 canvas.addEventListener('wheel',e=>{e.preventDefault();cam.radius=Math.max(3.3,Math.min(23,cam.radius*Math.exp(e.deltaY*.001)));renderFallback()},{passive:false});
 canvas.addEventListener('click',e=>{if(!window.fallbackHit)return;let x=e.clientX-canvas.getBoundingClientRect().left,y=e.clientY-canvas.getBoundingClientRect().top;
 let found=window.fallbackHit.findLast(h=>Math.hypot(h.x-x,h.y-y)<29);if(found)document.querySelector('#objectInfo').innerHTML='<h3>'+found.name+'</h3><p>'+found.desc+'</p>'});
}
function resizeFallback(){if(!canvas||!ctx)return;const r=canvas.getBoundingClientRect();canvas.width=Math.max(100,Math.floor(r.width*devicePixelRatio));canvas.height=Math.max(100,Math.floor(r.height*devicePixelRatio));renderFallback()}
function renderFallback(){
 if(!canvas||!ctx||!cam)return;
 const W=canvas.width,H=canvas.height,dpr=devicePixelRatio;
 ctx.setTransform(1,0,0,1,0,0);ctx.clearRect(0,0,W,H);ctx.fillStyle='#bccbd0';ctx.fillRect(0,0,W,H);
 let pos=[cam.target[0]+Math.cos(cam.pitch)*Math.cos(cam.yaw)*cam.radius,cam.target[1]+Math.cos(cam.pitch)*Math.sin(cam.yaw)*cam.radius,cam.target[2]+Math.sin(cam.pitch)*cam.radius];
 let f=unit(v3(cam.target,pos));let right=unit(cross(f,[0,0,1]));let up=unit(cross(right,f));
 const focal=Math.min(W,H)*1.17;const project=p=>{const d=v3(p,pos),depth=dot(d,f);if(depth<.12)return null;return [W*.5+dot(d,right)*focal/depth,H*.52-dot(d,up)*focal/depth,depth]};
 let faces=[];
 for(let [g,o] of Object.entries(MESHES)){
  if(hidden.has(g))continue;const alpha=g==='glass'?.42:g==='loft'?.74:g==='shell_high'?.43:1;
  for(let i=0;i<o.tri.length;i++){
   const f3=o.tri[i],pts=f3.map(j=>project(o.verts[j])); if(pts.some(p=>!p))continue;
   faces.push({pts,depth:(pts[0][2]+pts[1][2]+pts[2][2])/3,color:o.cols[i],alpha});
  }
 }
 faces.sort((a,b)=>b.depth-a.depth);
 for(let f of faces){ctx.globalAlpha=f.alpha;ctx.fillStyle=f.color;ctx.beginPath();ctx.moveTo(f.pts[0][0],f.pts[0][1]);ctx.lineTo(f.pts[1][0],f.pts[1][1]);ctx.lineTo(f.pts[2][0],f.pts[2][1]);ctx.closePath();ctx.fill()}
 ctx.globalAlpha=1;
 // Faint grout grid to convey scale, only if floor visible (projection overlays are subtle).
 if(!hidden.has('floor')){ctx.strokeStyle='rgba(106,117,118,.14)';ctx.lineWidth=Math.max(1,dpr*.6);for(let [a,b] of __GRIDLINES__){let pa=project(a),pb=project(b);if(!pa||!pb)continue;ctx.beginPath();ctx.moveTo(pa[0],pa[1]);ctx.lineTo(pb[0],pb[1]);ctx.stroke()}}
 window.fallbackHit=[];
 if(!hidden.has('labels')){for(let [name,pt,g,desc] of MARKERS){if(hidden.has(g))continue;let p=project(pt);if(!p)continue;let x=p[0],y=p[1];if(x<5||x>W-5||y<5||y>H-5)continue;
   ctx.font=(12*dpr)+'px Segoe UI,Arial';const pad=8*dpr;let tw=ctx.measureText(name).width;ctx.fillStyle='rgba(19,34,48,.89)';ctx.beginPath();ctx.roundRect(x-tw/2-pad,y-21*dpr,tw+2*pad,22*dpr,6*dpr);ctx.fill();ctx.fillStyle='#fff1cf';ctx.textAlign='center';ctx.fillText(name,x,y-6*dpr);ctx.textAlign='left';window.fallbackHit.push({x:x/dpr,y:(y-11*dpr)/dpr,name,desc});}}
 ctx.fillStyle='rgba(27,46,58,.75)';ctx.font=(12*dpr)+'px Segoe UI';ctx.fillText('Chế độ 3D Canvas • vẫn xoay/zoom được khi WebGL bị khóa',18*dpr,28*dpr);
}

</script></body></html>'''
# Use proper literal javascript replacement
html=head+get_plotlyjs()+"\n</script>\n<script>\n"+body.replace('__FIG__',layout_json).replace('__GROUP__',group_json).replace('__PHOTOS__',photo_json).replace('__MESHES__',mesh_json).replace('__MARKERS__',marker_json).replace('__GRIDLINES__',grid_json)
file=os.path.join(ROOT,'7150_XOAY_PHONG_3D.html')
with open(file,'w',encoding='utf8') as f:f.write(html)

readme='''# 7:50 — VỀ NHÀ | Room spatial prototype v4\n\n## Mở mô hình 3D\n\n- Mở `7150_XOAY_PHONG_3D.html` bằng Chrome / Edge trên Windows. KHÔNG cần Internet.\n- Kéo chuột trái để xoay; cuộn để zoom; kéo chuột phải để pan.\n- Các nút góc nhìn: Toàn cảnh, Mặt bằng, Góc PC, Lối đi, Từ cửa, Gác xép.\n- Có thể ẩn gác xép, hiển thị tường cao, nhãn, nội thất.\n- Bên phải có 9 ảnh phòng thật để tự đối chiếu.\n\n## Tệp giao Codex / Godot\n\n- `7150_PHONG_TRO_LAYOUT_v4.glb` — mô hình 3D thực, vật thể riêng; được đổi từ hệ Z-up trong HTML sang Y-up của glTF/Godot khi xuất. Không tự đảo hướng bàn sau khi nhập.\n- `7150_ROOM_LAYOUT_SOURCE.json` — dữ liệu vật thể/tọa độ có tên để Codex chỉnh.\n- `build_room_v4.py` — mã nguồn tạo model gốc; phải giữ lại khi sửa bố cục.\n\n## Quy tắc không gian đã chốt từ ảnh của người dùng\n\n1. Lối vào nằm ở hõm bên trái phía dưới sơ đồ, KHÔNG phải giữa cạnh dưới.\n2. Bên phải hành lang theo thứ tự: bếp, máy giặt cửa ngang đen, cửa WC.\n3. Bên trái hành lang: giá áo rồi tủ gỗ lớn.\n4. Cuối đường đi: cửa ra ban công bên trái cầu thang lên gác.\n5. Khu PC mở sang phải ở cuối hành lang; gác nằm phía trên cả hai máy.\n6. Bàn PC người dùng đặt dọc tường phía phải sơ đồ, người ngồi nhìn sang phải; cửa sổ nằm ở bức tường trên, bên trái người ngồi.\n7. Bàn PC Đức đặt vuông góc, trên bức tường phía dưới của vùng PC; Đức ngồi quay mặt xuống sơ đồ.\n8. Tủ lạnh nhỏ ở góc phía tường WC, cạnh Đức, mặt tủ hướng lên sơ đồ.\n\n## Hạn chế quan trọng\n\nHệ tọa độ: JSON/HTML = x (ngang), y (sâu), z (cao). GLB cho Godot = x (ngang), y (cao), z (-sâu), đã xoay khi xuất.\n\nCác số đo trên sơ đồ là XẤP XỈ do người dùng cung cấp. 1,35m là khoảng thông thủy đến chân bếp; độ nhô 0,66m được suy ra. Chiều cao gác và bề ngang WC/đồ nhỏ vẫn là placeholder, KHÔNG phải kết quả quét 3D. Việc nối các vách WC, khoảng hở quanh đầu cầu thang và hình dạng cửa có thể cần cập nhật khi có số đo hoặc người dùng xoay mô hình và phát hiện sai. Đây là spatial blockout dùng để CHỐT bố cục, chưa phải đồ họa hoàn chỉnh hay game chạy được.\n'''
with open(os.path.join(ROOT,'README.md'),'w',encoding='utf8') as f:f.write(readme)
print('parts',len(P),'groups',list(M.keys()))
print('size',[(n,round(os.path.getsize(os.path.join(ROOT,n))/1e6,2)) for n in ('7150_XOAY_PHONG_3D.html','7150_PHONG_TRO_LAYOUT_v4.glb','7150_ROOM_LAYOUT_SOURCE.json')])

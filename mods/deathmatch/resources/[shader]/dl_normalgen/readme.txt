Resource: dl_normalGen v0.0.3
Author: Ren712
Contact: knoblauch700@o2.pl

Description:
Normals for world objects (if not present in dff) are not present or if are generated 
using 'generate normals' flag in shader they might turn up improper. dl_lightmanager
lights might generate a simple variant of non interpolated normals based on scene depth. 
This resource generates normals that are smoothen and slight screen space normal mapping 
effect (based on colorRT) is applied. 

Core resource for deferred lighting:
dl_core: https://community.mtasa.com/index.php?p=resources&s=details&id=18510

dl_core is required for:
dl_lightmanager: https://community.mtasa.com/index.php?p=resources&s=details&id=18512
dl_flashlight: https://community.mtasa.com/index.php?p=resources&s=details&id=18514
dl_vehicles: https://community.mtasa.com/index.php?p=resources&s=details&id=18513
dl_blendshad: https://community.mtasa.com/?p=resources&s=details&id=18547
dl_projectiles: https://community.mtasa.com/?p=resources&s=details&id=18548
dl_normalgehttps://community.mtasa.com/?p=resources&s=details&id=18555n: 
dl_image3dlight: https://community.mtasa.com/?p=resources&s=details&id=18553
dl_material3dlight: https://community.mtasa.com/?p=resources&s=details&id=18554
dl_primitive3dlight: https://community.mtasa.com/?p=resources&s=details&id=18550

used by but not required:
dl_shader_detail: https://community.mtasa.com/?p=resources&s=details&id=18549
dl_carpaint: https://community.mtasa.com/?p=resources&s=details&id=18551
dl_ssao: https://community.mtasa.com/?p=resources&s=details&id=18552
dl_neon: https://community.mtasa.com/index.php?p=resources&s=details&id=18511

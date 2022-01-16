Resource: Shader reflective bump test 2.5
Author: Ren712
Contact: knoblauch700@o2.pl

version 2.5
-Fixed a bug in normal filter
-A proper reflective bump mapping code.

My aim was to understand the "reflective bump" effect 
known from enb series. This one is not as flashy, 
but works under shader model 2.0. Since I don't have
much time on my hands I'll just release it as it is.

The normals are generated using the sobel filter.
The enviroment reflection is a projected screen texture
(a bit streched and blured).I used parts of shader bloom 
from examples (blur effects and most of the lua code).

The effect looks good with bloom and contrast shader.
Since it is applied to world textures it will not work with
shader detail or roadshine.
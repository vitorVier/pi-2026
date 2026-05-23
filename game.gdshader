shader_type canvas_item;

void fragment() {
    vec4 color = texture(TEXTURE, UV);
    // Calcula o quão próximo o pixel está do branco puro (1.0, 1.0, 1.0)
    float brightness = (color.r + color.g + color.b) / 3.0;
    
    // Se for muito brilhante (perto de 1.0), torna transparente
    if (brightness > 0.95) { 
        color.a = 0.0;
    }
    
    COLOR = color;
}
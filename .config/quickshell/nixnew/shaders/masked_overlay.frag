#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 1) out vec4 fragColor;
layout(binding = 1) uniform sampler2D source;
layout(binding = 2) uniform sampler2D overlayItem;

layout(std140, binding = 0) uniform buf {
	mat4 qt_Matrix;
	float qt_Opacity;
	vec2 pOverlayPos;
	vec2 pOverlaySize;
	vec2 pMergeInset;
	float pMergeCutoff;
};

void main() {
	vec2 overlayCoord = (qt_TexCoord0 - pOverlayPos) / pOverlaySize;

	if (overlayCoord.x >= 0 && overlayCoord.y >= 0 && overlayCoord.x < 1 && overlayCoord.y < 1) {
		fragColor = texture(overlayItem, overlayCoord);

		if (fragColor.a != 0) {
			vec4 baseColor = texture(source, qt_TexCoord0);
			// imperfect but visually good enough for now. if more is needed we'll probably need a mask tex
			if (baseColor.a != 0
					&& fragColor.a < pMergeCutoff
					&& (texture(overlayItem, overlayCoord + vec2(0, pMergeInset.y)).a == 0
							|| texture(overlayItem, overlayCoord + vec2(pMergeInset.x, 0)).a == 0
							|| texture(overlayItem, overlayCoord + vec2(0, -pMergeInset.y)).a == 0
							|| texture(overlayItem, overlayCoord + vec2(-pMergeInset.x, 0)).a == 0)) {
				fragColor += baseColor * (1 - fragColor.a);
			}

			fragColor *= qt_Opacity;
			return;
		}
	}

	fragColor = texture(source, qt_TexCoord0) * qt_Opacity;
}

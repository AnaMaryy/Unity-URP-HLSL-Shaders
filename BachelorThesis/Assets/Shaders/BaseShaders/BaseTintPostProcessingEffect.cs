using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace Shaders.BasePostProcessing {

	[Serializable, VolumeComponentMenuForRenderPipeline("Thesis/BaseTintPostProcessingEffect"
		 , typeof(UniversalRenderPipeline))]
	public class BaseTintPostProcessingEffect : VolumeComponent, IPostProcessComponent {

		//tint effect
		public FloatParameter tintIntensity = new FloatParameter(1);
		public ColorParameter tintColor = new ColorParameter(Color.white);
		public bool IsActive() {
			return true;
		}

		public bool IsTileCompatible() {
			return false;
		}

	}

}

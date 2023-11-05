using TMPro;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace Shaders.BasePostProcessing {

	public class BaseTintRenderFeature : ScriptableRendererFeature {

		private TintPass tintPass;

		public override void Create() {
			tintPass = new TintPass();
		}

		public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData) {
			renderer.EnqueuePass(tintPass);
		}

		class TintPass : ScriptableRenderPass {

			private Material _mat;
			private int tintId = Shader.PropertyToID("_Temp");
			private RenderTargetIdentifier src, tint;

			public TintPass() {
				if (!_mat) {
					_mat = CoreUtils.CreateEngineMaterial("Test/BaseTintPass"); //put your shader here
				}
				renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing; // when do we want this pass to apply
			}

			public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData) {

				RenderTextureDescriptor desc = renderingData.cameraData.cameraTargetDescriptor;
				//create render texture / render target
				src = renderingData.cameraData.renderer.cameraColorTarget; //get the source from the camera
				cmd.GetTemporaryRT(tintId, desc, FilterMode.Bilinear);
				tint = new RenderTargetIdentifier(tintId);
			}

			//executing the pass
			public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData) {
				CommandBuffer commandBuffer = CommandBufferPool.Get("TintRenderFeature");
				VolumeStack volumes = VolumeManager.instance.stack;
				BaseTintPostProcessingEffect tintData = volumes.GetComponent<BaseTintPostProcessingEffect>();
				if (tintData.IsActive()) {
					_mat.SetColor("_OverlayColor", (Color)tintData.tintColor);
					_mat.SetFloat("_Intensity", (float)tintData.tintIntensity);

					Blit(commandBuffer, src, tint, _mat, 0); //where the thing is blitten into
					Blit(commandBuffer, tint, src);

				}
				context.ExecuteCommandBuffer(commandBuffer);
				CommandBufferPool.Release(commandBuffer);
			}

			public override void OnCameraCleanup(CommandBuffer cmd) {
				cmd.ReleaseTemporaryRT(tintId);
			}

		}

	}

}

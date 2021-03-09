using System;
using UnityEngine;
using UnityEngine.Rendering;
using Random = UnityEngine.Random;


namespace TheProxor.Outline.Services
{
    [Serializable]
    public class PostEffectOutlineComponent : IServiceComponent
    {
        #region Fields

        [Header("Items")]
        [SerializeField] private SpriteRenderer[] faces = default;


        [Header("Settings")]
        [SerializeField] private int outlineSortingOrder = default;
        [SerializeField] private Color outlineColor = default;
        [SerializeField, Range(0, 100)] private float outlineWidth = 10;
        [SerializeField, Range(0, 1)] private float outlineThreshold = 0.25f;
        [SerializeField] private bool isAnimated = true;
        [SerializeField] private bool isMultiRandomColor = true;


        private const string outlineShaderName = "Hidden/Outline Blit";

        private const string commandBufferName = "Outline Buffer";
        private const CameraEvent camEvent = CameraEvent.AfterImageEffects;

        private Material outlineMat;

        private MonoBehaviourService monoBehaviourService;

        private CommandBuffer commandBuffer;

        private RenderTexture spriteRenderTexture;

        private SpriteRenderer sr;

        private Camera cam;

        #endregion



        #region Methods

        public void Initialize()
        { 
            cam = Camera.main;

            if(cam == null)
            {
                Debug.LogError("Main camera is does not exists");
            }

            monoBehaviourService = Service.GetService<MonoBehaviourService>();
            monoBehaviourService.OnUpdate += OnUpdate;

            sr = new GameObject("Sr", typeof(SpriteRenderer)).GetComponent<SpriteRenderer>();

            
            sr.sprite = Sprite.Create(
                new Texture2D(cam.pixelWidth, cam.pixelHeight, UnityEngine.Experimental.Rendering.DefaultFormat.LDR, UnityEngine.Experimental.Rendering.TextureCreationFlags.None),
                cam.pixelRect, new Vector2(0.5f, 0.5f));

            var distance = 1f;

            sr.transform.parent = Camera.main.transform;
            sr.transform.localPosition = Vector3.zero + new Vector3(0, 0, distance);

            var worldScreenH = (distance + 1f) * Mathf.Tan(Camera.main.fieldOfView * 0.5f * Mathf.Deg2Rad);
            var worldScreenW = worldScreenH * Camera.main.aspect;

            sr.transform.localScale = new Vector3(worldScreenW / sr.sprite.bounds.size.x, worldScreenH / sr.sprite.bounds.size.y);

            if (isMultiRandomColor)
            {
                InitializeCommandBufferMultiColor();
            }
            else
            {
                InitializeCommandBuffer();
            }
        }

        private void InitializeCommandBuffer()
        {
            outlineMat = new Material(Shader.Find(outlineShaderName));

            outlineMat.SetInt("_IsMultiColor", 0);

            int outlinePass = outlineMat.FindPass("Outline");

            commandBuffer = new CommandBuffer();
            commandBuffer.name = commandBufferName;

            var activeTex = Shader.PropertyToID("_ActiveTex");

            commandBuffer.GetTemporaryRT(activeTex, cam.pixelWidth, cam.pixelHeight, 24, FilterMode.Point, RenderTextureFormat.ARGB32);

            spriteRenderTexture = new RenderTexture(cam.pixelWidth, cam.pixelHeight, 24);

            commandBuffer.SetRenderTarget(activeTex);
            commandBuffer.ClearRenderTarget(true, true, new Color(0f, 0f, 0f, 0f));

            foreach (SpriteRenderer spriteRenderer in faces)
            {
                commandBuffer.DrawRenderer(spriteRenderer, spriteRenderer.material);
            }

            commandBuffer.Blit(Texture2D.blackTexture, spriteRenderTexture);
            commandBuffer.Blit(activeTex, spriteRenderTexture, outlineMat, outlinePass);

            commandBuffer.CopyTexture(spriteRenderTexture, sr.sprite.texture);

            commandBuffer.ReleaseTemporaryRT(activeTex);

            cam.AddCommandBuffer(camEvent, commandBuffer);
        }

        private void InitializeCommandBufferMultiColor()
        {
            outlineMat = new Material(Shader.Find(outlineShaderName));

            outlineMat.SetInt("_IsMultiColor", 1);

            commandBuffer = new CommandBuffer();
            commandBuffer.name = commandBufferName;

            var activeTex = Shader.PropertyToID("_ActiveTex");
            var tmpRT = Shader.PropertyToID("_TmpRT");

            commandBuffer.GetTemporaryRT(activeTex, cam.pixelWidth, cam.pixelHeight, 24, FilterMode.Point, RenderTextureFormat.ARGB32);
            commandBuffer.GetTemporaryRT(tmpRT, cam.pixelWidth, cam.pixelHeight, 24, FilterMode.Point, RenderTextureFormat.ARGB32);

            spriteRenderTexture = new RenderTexture(cam.pixelWidth, cam.pixelHeight, 24);

            int mtrPass = outlineMat.FindPass("MTR");
            int outlinePass = outlineMat.FindPass("Outline");

            RenderTargetIdentifier[] texturesID =
            {
                activeTex,
                tmpRT,
            };

            commandBuffer.SetRenderTarget(texturesID, tmpRT);
            commandBuffer.ClearRenderTarget(true, true, new Color(0f, 0f, 0f, 0f));

            foreach (SpriteRenderer spriteRenderer in faces)
            {
                Color randomColor = new Color(Random.Range(0f, 1f), Random.Range(0f, 1f), Random.Range(0f, 1f), 1f);
                commandBuffer.SetGlobalColor("_OutlineTempColor", randomColor);
                commandBuffer.DrawRenderer(spriteRenderer, outlineMat, 0, mtrPass);
            }

            commandBuffer.SetGlobalTexture("_ColorTex", tmpRT);
            commandBuffer.Blit(Texture2D.blackTexture, spriteRenderTexture);
            commandBuffer.Blit(activeTex, spriteRenderTexture, outlineMat, outlinePass);

            commandBuffer.CopyTexture(spriteRenderTexture, sr.sprite.texture);

            commandBuffer.ReleaseTemporaryRT(activeTex);
            commandBuffer.ReleaseTemporaryRT(tmpRT);

            cam.AddCommandBuffer(camEvent, commandBuffer);
        }

        private void Cleanup()
        {
            if (commandBuffer != null)
                commandBuffer.Clear();

            spriteRenderTexture.Release();

            if(cam == null)
            {
                return;
            }

            foreach (var buf in cam.GetCommandBuffers(camEvent))
                if (buf.name == commandBufferName)
                    cam.RemoveCommandBuffer(camEvent, buf);
        }

        private void OnUpdate()
        {
            UpdateMatSettings();
        }

        public void UpdateMatSettings()
        {
            sr.sortingLayerName = "Default";
            sr.sortingOrder = outlineSortingOrder;

            outlineMat.SetColor("_OutlineColor", outlineColor);
            outlineMat.SetFloat("_Threshold", outlineThreshold);
            outlineMat.SetFloat("_OutlineWidth", outlineWidth);
            outlineMat.SetInt("_IsAnimated", Convert.ToInt32(isAnimated));
        }

        public void Deinitialize()
        {
            Cleanup();
            monoBehaviourService.OnUpdate -= OnUpdate;
        }

        #endregion
    }
}
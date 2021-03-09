using System;
using System.Linq;
using UnityEngine;
using Random = UnityEngine.Random;


namespace TheProxor.Outline.Services
{
    [Serializable]
    public class SpriteOutlineComponent : IServiceComponent
    {
        #region Fields

        [Header("Items")]
        [SerializeField] private SpriteRenderer[] faces = default;
        [SerializeField] private SpriteRenderer[] walls = default;
        [SerializeField] private SpriteRenderer[] wallsOverlay = default;

        [Header("Settings")]
        [SerializeField] private int outlineSortingOrder = default;
        [SerializeField] private Color outlineColor = default;
        [SerializeField, Range(0, 100)] private float outlineWidth = 10;
        [SerializeField, Range(0, 1)] private float outlineThreshold = 0.25f;
        [SerializeField] private bool isAnimated = true;
        [SerializeField] private bool isMultiRandomColor = true;


        private const string customSpriteShaderName = "Custom/Sprite";
        private const string outlineShaderName = "Custom/Sprites Outline";

        private Material outlineMat;
        private Material spriteMat;
        private Material spriteOverlayMat;

        private MonoBehaviourService monoBehaviourService;

        private Color[] multiRandomColors;
        private MaterialPropertyBlock props;

        #endregion



        #region Class Lifecycle

        public void Initialize()
        {
            if (walls.Length == 0 || faces.Length == 0 || wallsOverlay.Length == 0)
            {
                Debug.LogError("Walls and faces count could't be equel <b>zero</b>");
                return;
            }

            monoBehaviourService = Service.GetService<MonoBehaviourService>();

            spriteMat = new Material(Shader.Find(customSpriteShaderName));
            spriteOverlayMat = new Material(Shader.Find(customSpriteShaderName));
            outlineMat = new Material(Shader.Find(outlineShaderName));

            foreach (var wall in walls)
            {
                wall.material = spriteMat;
            }

            foreach (var overlayWall in wallsOverlay)
            {
                overlayWall.material = spriteOverlayMat;
            }

            foreach (var face in faces)
            {
                face.material = outlineMat;
            }

            SetupMultiColor();

            monoBehaviourService.OnUpdate += OnUpdate;
        }


        public void Deinitialize()
        {
            monoBehaviourService.OnUpdate -= OnUpdate;
        }

        #endregion



        #region Methods

        private void SetupMultiColor()
        {
            props = new MaterialPropertyBlock();
            faces.First().GetPropertyBlock(props);
            multiRandomColors = new Color[faces.Length];
            for (int i = 0; i < faces.Length; i++)
            {
                multiRandomColors[i] = new Color(Random.Range(0f, 1f), Random.Range(0f, 1f), Random.Range(0f, 1f), 1f);
            }         
        }


        private void UpdateMatSettings()
        {
            int wallSoringOrder = walls.First().sortingOrder;
            int wallOverlaySoringOrder = wallsOverlay.First().sortingOrder;
            int faceSoringOrder = faces.First().sortingOrder;

            outlineMat.SetInt("_StencilMask_1", outlineSortingOrder);
            outlineMat.SetInt("_StencilMask_2", faceSoringOrder);
            outlineMat.SetFloat("_Threshold", outlineThreshold);
            outlineMat.SetFloat("_OutlineWidth", outlineWidth);
            outlineMat.SetInt("_IsAnimated", Convert.ToInt32(isAnimated));

            spriteMat.SetInt("_StencilMask", wallSoringOrder);
            spriteOverlayMat.SetInt("_StencilMask", wallOverlaySoringOrder);

            if(isMultiRandomColor)
            {
                for(int i = 0; i < faces.Length; i++)
                {
                    props.SetColor("_OutlineColor", multiRandomColors[i]);
                    props.SetTexture("_MainTex", faces[i].sprite.texture);
                    faces[i].SetPropertyBlock(props);
                }
            }
            else
            {
                outlineMat.SetColor("_OutlineColor", outlineColor);
            }
        }

        #endregion



        #region Event Handlers

        private void OnUpdate() =>
            UpdateMatSettings();

        #endregion
    }
}
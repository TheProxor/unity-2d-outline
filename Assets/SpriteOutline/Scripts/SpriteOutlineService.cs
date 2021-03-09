using UnityEngine;


namespace TheProxor.Outline.Services
{
    public class SpriteOutlineService : Service
    {
        #region Fields

        [SerializeField] private SpriteOutlineComponent serviceComponent = default;

        #endregion



        #region Methods

        protected override void Awake()
        {
            base.Awake();
            SetComponents(
                            serviceComponent
                         );
        }

        #endregion    
    }
}

using UnityEngine;


namespace TheProxor.Outline.Services
{
    public class PostEffectOutlineService : Service
    {
        #region Fields

        [SerializeField] private PostEffectOutlineComponent serviceComponent = default;

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

using System;
using UnityEngine;


namespace TheProxor
{
    public class MonoBehaviourService : Service
    {
        #region Events

        public event Action OnAwake;
        public event Action OnStart;
        public event Action OnUpdate;
        public event Action OnDestoryObject;
        public event Action OnEnableObject;
        public event Action OnDisableObject;

        #endregion



        #region Methods

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.BeforeSceneLoad)]
        public static void OnLoad()
        {
            CreateSelfInstance<MonoBehaviourService>();
        }

        #endregion



        #region Unity Lifecycle

        protected override void Awake()
        {
            base.Awake();
            OnAwake?.Invoke();
        }


        private void Update()
        {
            OnUpdate?.Invoke();
        }


        private void OnEnable()
        {
            OnEnableObject?.Invoke();
        }


        private void OnDisable()
        {
            OnDisableObject?.Invoke();
        }


        protected override void Start()
        {
            base.Start();
            OnStart?.Invoke();
        }


        protected override void OnDestroy()
        {
            OnDestoryObject?.Invoke();
            base.OnDestroy();
        }

        #endregion
    }
}

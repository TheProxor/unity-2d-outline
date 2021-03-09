using System;
using System.Collections.Generic;
using UnityEngine;


namespace TheProxor
{
    public abstract class Service : MonoBehaviour, IInitializable, IDeitializable
    {
        #region Fields

        private static readonly Dictionary<Type, Service> services = new Dictionary<Type, Service>();

        protected readonly Dictionary<Type, IServiceComponent> serviceComponents = new Dictionary<Type, IServiceComponent>();

        #endregion



        #region Methods

        public static T GetService<T>() where T : Service
        {
            return services[typeof(T)] as T;
        }


        public bool TryGetServiceComponent<T>(out IServiceComponent value) where T : IServiceComponent
        {
            return serviceComponents.TryGetValue(typeof(T), out value);
        }


        public T GetServiceComponent<T>() where T : IServiceComponent
        {
            return (T)serviceComponents[typeof(T)];
        }


        public void SetComponents(params IServiceComponent[] typesComponents)
        {
            foreach (var component in typesComponents)
            {
                serviceComponents.Add(component.GetType(), component);
            }
        }


        private void AddCurrentService()
        {
            Type currentType = GetType();

            if (!services.ContainsKey(currentType))
            {
                services.Add(GetType(), this);
            }
            else
            {
                Debug.LogError($"Service <b>{currentType.Name}</b> already exists!");
            }
        }

        #endregion



        #region Static Methods

        protected static T CreateSelfInstance<T>() where T : Component
        {
            Type selfType = typeof(T);

            var _object = FindObjectOfType(selfType);

            if (_object == null)
            {
                return (T)(new GameObject(selfType.Name, selfType).GetComponent(selfType));
            }
            else
            {
                return (T)_object;
            }
        }

        #endregion



        #region Unity Lifecycle

        protected virtual void Awake()
        {
            DontDestroyOnLoad(gameObject);

            AddCurrentService();
        }


        protected virtual void Start()
        {
            Initialize();
        }


        protected virtual void OnDestroy()
        {
            Deinitialize();
        }

        #endregion



        #region Object Lifecycle

        public virtual void Initialize()
        {
            foreach (var component in serviceComponents.Values)
            {
                component.Initialize();
            }
        }


        public virtual void Deinitialize()
        {
            foreach (var component in serviceComponents.Values)
            {
                component.Deinitialize();
            }
        }

        #endregion
    }
}

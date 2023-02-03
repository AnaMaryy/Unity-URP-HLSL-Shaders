using UnityEngine;
using UnityEngine.Assertions;

public abstract class MonoSingleton<T> : MonoBehaviour where T : class
{
	public static T Instance { get; private set; }

	protected virtual void Awake()
	{
		Assert.IsNull(Instance, "There can be only one instance of: " + typeof(T));
		Instance = this as T;
	}
}



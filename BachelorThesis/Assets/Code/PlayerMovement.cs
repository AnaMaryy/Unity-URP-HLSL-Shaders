
using UnityEngine;

public class PlayerMovement : MonoBehaviour
{
    public float Speed = 12f;
    public float UpDownSpeed = 12f;
    
    void Update()
    {
      

        //if (!SceneController.Instance.CanMove) return;
        
        if (Input.GetKey("space"))
        {
            transform.position += new Vector3(0, 1, 0) * (UpDownSpeed * Time.deltaTime);
            //Controller.Move(new Vector3(0, 1, 0) * (UpDownSpeed * Time.deltaTime));
        }
        if (Input.GetKey(KeyCode.LeftShift))
        {
            transform.position += new Vector3(0, -1, 0) * (UpDownSpeed * Time.deltaTime);
           // Controller.Move(new Vector3(0, -1, 0) * (UpDownSpeed * Time.deltaTime));
        }
        float x = Input.GetAxis("Horizontal");
        float z = Input.GetAxis("Vertical");
        Vector3 direction = transform.right * x + transform.forward * z;

        transform.position += direction * (Speed * Time.deltaTime);
        //Controller.Move(direction * (Speed * Time.deltaTime));


    }
}

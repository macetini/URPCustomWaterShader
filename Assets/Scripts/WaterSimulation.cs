using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WaterSimulation : MonoBehaviour
{
    public float wavelength1 = 10;
    public float amplitude1 = 1;
    public float speed1 = 1;
    public Vector2 direction1 = new Vector2(1, 0);
    public float steepnes1 = 0.5f;    

    public float wavelength2 = 10;
    public float amplitude2 = 1;
    public float speed2 = 1;
    public Vector2 direction2 = new Vector2(1, 0);
    public float steepnes2 = 0.5f;

    // Update is called once per frame
    void OnDrawGizmos()
    {  
        WaveVO wave1 = new WaveVO();
        wave1.wavelength = wavelength1;
        wave1.amplitude = amplitude1;
        wave1.speed = speed1;
        wave1.direction = direction1;
        wave1.steepnes = steepnes1;

        WaveVO wave2 = new WaveVO();
        wave2.wavelength = wavelength2;
        wave2.amplitude = amplitude2;
        wave2.speed = speed2;
        wave2.direction = direction2;
        wave2.steepnes = steepnes2;

        for (float i = 0; i < 30; i++)
        {
            for (float j = 0; j < 30; j++)
            {
                Vector3 point = new Vector3(i, 0, j);                

                TangentSpace tangentSpace = new TangentSpace();

                point += GetGesternWave(wave1, ref tangentSpace, point, Time.time);
                point += GetGesternWave(wave2, ref tangentSpace, point, Time.time);

                Gizmos.color = Color.black;

                Gizmos.DrawSphere(point, 0.15f);

                Gizmos.color = Color.green;

                tangentSpace = calculateTangentSpace(tangentSpace);	

                Matrix4x4 texSpace = new Matrix4x4(tangentSpace.binormal, tangentSpace.normal, tangentSpace.tangent, new Vector3());

                Vector3 normal = new Vector3(0, 1, 0);
                
                Vector3 finalNormal = Vector3.Normalize(texSpace * normal);                

                Gizmos.DrawLine(point, point + finalNormal);
            }
        }
    }

    private Vector3 GetGesternWave(WaveVO wave, ref TangentSpace tangentSpace, Vector3 p, float t)
    {
        float w = Mathf.Sqrt(9.81f * ((2f * Mathf.PI) / wave.wavelength));
        //float w = 2 * UNITY_PI / wave.wavelength;
        float PHI_t = wave.speed * w * t;
        Vector2 D = wave.direction;
        D.Normalize();
        float Q = wave.steepnes / (w * wave.amplitude * 2);

        float f1 = w * Vector2.Dot(D, new Vector2(p.x, p.z)) + PHI_t;
        float S = Mathf.Sin(f1);
        float C = Mathf.Cos(f1);

        float WA = w * wave.amplitude;
        float WAS = WA * S;
        float WAC = WA * C;

        tangentSpace.binormal += new Vector3
              (
                  Q * (D.x * D.x) * WAS,
                  D.x * WAC,
                  Q * (D.x * D.y) * WAS
              );

        tangentSpace.tangent += new Vector3
        (
            Q * (D.x * D.y) * WAS,
            D.y * WAC,
            Q * (D.y * D.y) * WAS
        );

        tangentSpace.normal += new Vector3
        (
            D.x * WAC,
            Q * WAS,
            D.y * WAC
        );

        float f3 = Mathf.Cos(f1);
        float f4 = Q * wave.amplitude * f3;

        return new Vector3
        (
            f4 * D.x,                       // X
            wave.amplitude * Mathf.Sin(f1), // Y
            f4 * D.y                        // Z
        );
    }

    TangentSpace calculateTangentSpace(TangentSpace tangentSpace)
    {
        tangentSpace.binormal = new Vector3(
            1 - tangentSpace.binormal.x,
            tangentSpace.binormal.y,
            -tangentSpace.binormal.z
        );
        tangentSpace.tangent = new Vector3(
            -tangentSpace.tangent.x,
            tangentSpace.tangent.y,
            1 - tangentSpace.tangent.z
        );
        tangentSpace.normal = new Vector3(
            -tangentSpace.normal.x,
            1 - tangentSpace.normal.y,
            -tangentSpace.normal.z
        );

        return tangentSpace;
    }
}

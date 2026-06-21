using UnityEngine;

public class GrassRenderer : MonoBehaviour
{
    [SerializeField] private Mesh _mesh;
    [SerializeField] private Material _grassMat;
    [SerializeField] private Material _groundMat;
    [SerializeField] [Min(0)] private float _height;
    [SerializeField] [Range(0f, 2f)] private float _grassThickness;
    [SerializeField] [Min(1)] private int _planesCount;
    [SerializeField] [Min(0)] private float _grassOffset;

    private MaterialPropertyBlock _block;
    
    private Matrix4x4[] _matrices;
    private float[] _normCurHeights;
    private float[] _curHeights;

    private void Awake()
    {
        InstanceSetup();
    }

    private void Update()
    {
        DrawGrassInstanced();
    }

    private void OnValidate()
    {
        InstanceSetup();
        DrawGrassInstanced();
    }

    private float Remap(float value, float from1, float to1, float from2, float to2)
    {
        return (value - from1) / (to1 - from1) * (to2 - from2) + from2;
    }

    private void InstanceSetup()
    {
        _matrices = new Matrix4x4[_planesCount];
        _normCurHeights = new float[_planesCount];
        _curHeights = new float[_planesCount];

        _block = new MaterialPropertyBlock();
        
        float heightDelta = _height / _planesCount;
        float normalizedHeightDelta = Remap(heightDelta, 0,_height, 0, 1f);

        for (int i = 0; i < _planesCount; i++)
        {
            Vector3 position = transform.position;
            Quaternion rotation = Quaternion.identity;
            Vector3 scale = Vector3.one;

            Matrix4x4 mat = Matrix4x4.TRS(position, rotation, scale);

            _matrices[i] = mat;

            _normCurHeights[i] = normalizedHeightDelta * i;
            _curHeights[i] = heightDelta * i;
        }
        _block.SetFloatArray("_normCurHeights", _normCurHeights);
        _block.SetFloatArray("_curHeights", _curHeights);
        
        _grassMat.SetFloat("startOffset", _grassOffset);
        _grassMat.SetFloat("grassThickness", _grassThickness);
    }

    private void DrawGrassInstanced()
    {
        if (_groundMat == null)
        {
            return;
        }
        Graphics.DrawMesh(_mesh, transform.position, transform.rotation, _groundMat, 0, Camera.current,0);

        if (_grassMat == null)
        {
            return;
        }
        Graphics.DrawMeshInstanced(_mesh, 0, _grassMat, _matrices, _planesCount, _block);
    }
}

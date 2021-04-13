import coremltools
import coremltools.proto.FeatureTypes_pb2 as ft

spec = coremltools.utils.load_spec("flirFever/faceMaskConverted3.mlmodel")

print(spec.description)
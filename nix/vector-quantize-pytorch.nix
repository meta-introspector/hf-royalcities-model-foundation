{ lib, buildPythonPackage, hatchling, torch, einops, src }:
buildPythonPackage {
  pname = "vector-quantize-pytorch"; version = "1.28.0"; pyproject = true;
  inherit src; build-system = [ hatchling ]; dependencies = [ torch einops ]; doCheck = false;
}

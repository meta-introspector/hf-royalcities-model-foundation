{ lib, buildPythonPackage, setuptools, torch, src }:
buildPythonPackage {
  pname = "v-diffusion-pytorch"; version = "0.0.2"; pyproject = true;
  inherit src; build-system = [ setuptools ]; dependencies = [ torch ]; doCheck = false;
}

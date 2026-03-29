{ lib, buildPythonPackage, setuptools, torch, src }:
buildPythonPackage {
  pname = "ema-pytorch"; version = "0.2.3"; pyproject = true;
  inherit src; build-system = [ setuptools ]; dependencies = [ torch ]; doCheck = false;
}

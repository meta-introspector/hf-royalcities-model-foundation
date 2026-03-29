{ lib, buildPythonPackage, setuptools, torch, src }:
buildPythonPackage {
  pname = "alias-free-torch"; version = "0.0.6"; pyproject = true;
  inherit src; build-system = [ setuptools ]; dependencies = [ torch ]; doCheck = false;
}

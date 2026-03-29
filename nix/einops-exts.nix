{ lib, buildPythonPackage, setuptools, einops, src }:
buildPythonPackage {
  pname = "einops-exts"; version = "0.0.4"; pyproject = true;
  inherit src; build-system = [ setuptools ]; dependencies = [ einops ]; doCheck = false;
}

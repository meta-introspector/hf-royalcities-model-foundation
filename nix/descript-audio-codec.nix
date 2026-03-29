{ lib, buildPythonPackage, setuptools, torch, torchaudio, einops, src }:
buildPythonPackage {
  pname = "descript-audio-codec"; version = "1.0.0"; pyproject = true;
  inherit src; build-system = [ setuptools ]; dependencies = [ torch torchaudio einops ]; doCheck = false;
}

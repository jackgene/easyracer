{ pkgs ? import <nixpkgs> {} }:
let
  my-python-packages = p: with p; [
    reactivex
    aiohttp
    psutil
    testcontainers
    pytest
    pytest-asyncio
    deprecation
    docker
    wrapt
  ];
  my-python = pkgs.python3.withPackages my-python-packages;
in my-python.env

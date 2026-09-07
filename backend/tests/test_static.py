from fastapi import FastAPI
from fastapi.testclient import TestClient
from starlette.routing import Mount

from app import static
from app.main import app

client = TestClient(app)


def test_mount_static_skips_missing_directory(tmp_path, monkeypatch):
    monkeypatch.setattr(static, "STATIC_DIR", tmp_path / "does-not-exist")
    fresh = FastAPI()
    static.mount_static(fresh)
    assert not any(isinstance(route, Mount) for route in fresh.routes)


def test_mount_static_mounts_existing_directory(tmp_path, monkeypatch):
    (tmp_path / "index.html").write_text("<p>hello</p>", encoding="utf-8")
    monkeypatch.setattr(static, "STATIC_DIR", tmp_path)
    fresh = FastAPI()
    static.mount_static(fresh)
    assert TestClient(fresh).get("/").text == "<p>hello</p>"


def test_api_route_is_not_shadowed_by_the_static_mount():
    # StaticFiles at "/" is a catch-all, so this guards the mount ordering
    # in app.main.
    response = client.get("/api/health")
    assert response.headers["content-type"].startswith("application/json")


def test_unknown_path_returns_404():
    assert client.get("/nope").status_code == 404

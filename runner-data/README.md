# Actions Runner Data

This directory contains the Gitea Actions runner data and configuration.

## Files

- `.runner` - Runner registration information (auto-generated, do not edit)
- `config.yaml` - Runner configuration

## Configuration

The `config.yaml` file configures how the act_runner spawns job containers.

### Key Configuration: Network

The most important setting is the container network:

```yaml
container:
  network: gitea
```

This ensures that job containers are attached to the `gitea` Docker network, allowing them to:
- Resolve the `server` hostname (Gitea instance)
- Perform git operations (clone, checkout, push)
- Access internal Docker networking

**Without this setting**, job containers cannot reach the Gitea server and git operations will fail with:
```
fatal: unable to access 'http://server:3000/...': Could not resolve host: server
```

## Troubleshooting

### Job containers can't reach Gitea

**Symptom**: Workflows fail with "Could not resolve host: server"

**Solution**:
1. Verify `config.yaml` exists: `docker exec atomicqms-runner ls -la /data/config.yaml`
2. Verify network setting: `docker exec atomicqms-runner cat /data/config.yaml | grep network`
3. Restart runner: `docker compose restart runner`

### Check runner is using config

```bash
# Check runner logs
docker logs atomicqms-runner --tail 50

# Verify config is loaded
docker exec atomicqms-runner cat /data/config.yaml
```

## More Information

- [Gitea Actions Runner Documentation](https://docs.gitea.com/usage/actions/quickstart)
- [act_runner Configuration](https://gitea.com/gitea/act_runner/src/branch/main/internal/pkg/config/config.example.yaml)

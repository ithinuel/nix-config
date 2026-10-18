# Secrets naming scheme

    ${scope}[.${who}].${function}[.${subject}].enc.${format}

`scope` is a real hostname or the reserved literal **`global`**; `who` (slot 2)
names the *explicit unlocker* and is mutually exclusive with the function.
Roles are strictly positional:

- **scope** — the host the secret belongs to, or `global` for content that is
  identical on every host. `global` is reserved: no host may be named `global`.
- **who** (optional) — a `username` (or the group token `users`, under
  `global` only): the secret is unlocked by that user's/group's age keys.
  If `who` is absent, the scope's own machine keys unlock it: *that host's*
  key under a hostname, *all hosts'* keys under `global`.
- **function** — what the secret is: `pass`, `agekey`, `store-key`,
  `cert-key`, `secrets`, `allowed-signers`, … Use hyphens inside compound
  function names; dots are reserved for separating roles.
- **subject** (optional, right after the function) — the user or service the
  secret is *about*, e.g. `pass.ithinuel` = "password for ithinuel". Use this
  for secrets about a user that must nevertheless be host-unlocked (the
  bootstrap files that *carry* a user's key or password cannot require that
  user's key to open). A subject is descriptive, never restrictive.
- **format** — the file *type* of the encrypted container, from a closed
  vocabulary: `yaml`/`json`/`ini`/`dotenv` when sops parses the file and a
  `key =` extracts from it; `pem` for certificates and keys that tools open
  directly; `txt` for everything else (opaque single values, sops-nix
  `format = "binary"`). Never invent new ones. Note the extension names the
  *encrypted file on disk*, not the value it delivers after decryption — a
  `.enc.yaml` container may well deliver a bare string via `key =`.

The four scope × who combinations:

| | host-unlocked | user-unlocked |
| --- | --- | --- |
| **per host** | `tleilax.fn.enc.fmt` | `tleilax.ithinuel.fn.enc.fmt` |
| **portable** | `global.fn.enc.fmt` | `global.users.fn.enc.fmt` |

Per-host cells unlock with that host's key; per-host user cells with that
user's key on that host. `global.fn.enc.fmt` opens with all hosts' keys;
`global.users.fn.enc.fmt` with every user's keys, everywhere. A per-person
spelling like `global.ithinuel.fn.enc.fmt` opens only with that person's
keys, everywhere.

Examples:

| File | Meaning |
| --- | --- |
| `tleilax.pass.ithinuel.enc.txt` | ithinuel's login password, host-unlocked |
| `tleilax.agekey.ithinuel.enc.txt` | ithinuel's age key, host-unlocked (bootstrap) |
| `tleilax.ithinuel.obsidian-mcp-key.enc.yaml` | ithinuel's MCP secret on tleilax, user-unlocked |
| `ix.llm.cert-key.enc.pem` | TLS key for the llm service, host-unlocked |
| `global.users.allowed-signers.enc.txt` | ssh allowed_signers, any user's key, any host |
| `ix.secrets.forgejo.enc.yaml` | forgejo's app secrets, unlocked by ix's host key |

## Group membership and rotation

The *class* of recipients is in the name; the exact *key set* of each group
(all hosts / all users) is defined in `.sops.yaml`. Therefore:

- **Onboarding a host** — add its host key and its per-host user keys to the
  groups in `.sops.yaml`, then `sops rotate` every `global.*` secret.
- **Onboarding a user** — add their per-host keys to the `users` group (and a
  per-person group if you use `global.<username>.*`), then rotate the
  affected `global.users.*` / `global.<username>.*` secrets.

With a single user, the `users` and per-person groups coincide; they express
different intents — "any current or future user" vs. "this specific person" —
so do not let them drift apart silently.

## Caveats

- Usernames and function names share a namespace (slot 2 is a username or
  absent, slot 3 is the function), so a function name must never equal a
  username. Under `global.`, slot 2 must additionally not be a function named
  `users` (or a username, once per-person rules exist).
- Public-key material is not automatically public *data*:
  `global.users.allowed-signers.enc.txt` contains only public keys and
  principals, but its inventory maps which devices (including work machines)
  are trusted to sign, so it stays encrypted on purpose — do not "demote" it
  to a plain repo file.
- `global.*` names imply a recipient *class*, not a fixed key list — consult
  `.sops.yaml` for membership. All other names determine their key directly.

## 0.1.4

- `@TableWidget`: if the mixin defines `showXXXCell`, generated headers and cells wrap that column with `if (showXXXCell(context))`.

## 0.1.3

- Guard generated `fromJson` calls when `resp.res` is null.
- Skip `*Fetch` helper generation when the request type lacks `pageNum` and `pageSize` fields.
- Default generated `MyClient` template sets `prefix` to `http://127.0.0.1:8080`.

## 0.1.2

- Backward compatible with **0.1.1** for package consumers (same annotations and generated shape).
- Raise `build` to **^4.0.0** (works with current `json_serializable` / `build_runner` stacks).
- Widen **`analyzer` to `>=8.4.1 <14.0.0`** so apps can resolve newer `json_serializable` (analyzer 10+) in the same workspace as this package.
- Depend on **`component_set` ^0.1.2**.

## 0.1.1

- Generated list `*Fetch` helpers use `IPaginationController<T>`; import a concrete
  definition in the same library as your `part` file (see `example/`, e.g. `component_set`).
- Fix generated fetch error message when reporting `resp.code`.
- Refresh example (`networkApi`, `build_runner` outputs) and metadata for publishing.

## 0.1.0

- Initial version.

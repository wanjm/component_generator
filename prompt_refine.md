## 2026-08-28 17:02:29

1. in compoent_generator, when generate TableWidget, if there is mehtod showXXXCell, plese call it to check whether genearte DataHeader or DataCell;
2. In component_generator, when generating TableWidget, if a showXXXCell method exists, call it to decide whether to generate the DataColumn (header) and DataCell;


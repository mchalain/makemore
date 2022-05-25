#include <QApplication>
#include <QTableView>

#include "Viewer.hpp"

int main(int argc, char * argv[])
{
	QApplication app(argc, argv);
	QTableView table;
	Viewer viewer;

	table.setModel(&viewer);
	table.show();
	return app.exec();
}

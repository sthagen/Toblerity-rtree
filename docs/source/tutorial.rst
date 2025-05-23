.. _tutorial:

Tutorial
------------------------------------------------------------------------------

This tutorial demonstrates how to take advantage of :ref:`Rtree <home>` for
querying data that have a spatial component that can be modeled as bounding
boxes.


Creating an index
..............................................................................

The following section describes the basic instantiation and usage of
:ref:`Rtree <home>`.

Import
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

After :ref:`installing <installation>` :ref:`Rtree <home>`, you should be able to
open up a Python prompt and issue the following:

.. code-block:: pycon

  >>> from rtree import index

:py:mod:`rtree` is organized as a Python package with a couple of modules
and two major classes - :py:class:`rtree.index.Index` and
:py:class:`rtree.index.Property`. Users manipulate these classes to interact
with the index.

Construct an instance
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

After importing the index module, construct an index with the default
construction:

.. code-block:: pycon

  >>> idx = index.Index()

.. note::

    While the default construction is useful in many cases, if you want to
    manipulate how the index is constructed you will need pass in a
    :py:class:`rtree.index.Property` instance when creating the index.

Create a bounding box
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

After instantiating the index, create a bounding box that we can
insert into the index:

.. code-block:: pycon

  >>> left, bottom, right, top = (0.0, 0.0, 1.0, 1.0)

.. note::

    The coordinate ordering for all functions are sensitive the the index's
    :py:attr:`~rtree.index.Index.interleaved` data member. If
    :py:attr:`~rtree.index.Index.interleaved` is False, the coordinates must
    be in the form [xmin, xmax, ymin, ymax, ..., ..., kmin, kmax]. If
    :py:attr:`~rtree.index.Index.interleaved` is True, the coordinates must be
    in the form [xmin, ymin, ..., kmin, xmax, ymax, ..., kmax].

Insert records into the index
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Insert an entry into the index:

.. code-block:: pycon

  >>> idx.insert(0, (left, bottom, right, top))

.. note::

    Entries that are inserted into the index are not unique in either the
    sense of the `id` or of the bounding box that is inserted with index
    entries. If you need to maintain uniqueness, you need to manage that before
    inserting entries into the Rtree.

.. note::

    Inserting a point, i.e. where left == right && top == bottom, will
    essentially insert a single point entry into the index instead of copying
    extra coordinates and inserting them. There is no shortcut to explicitly
    insert a single point, however.

Query the index
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

There are three primary methods for querying the index.
:py:meth:`rtree.index.Index.intersection` will return you index entries that
*cross* or are *contained* within the given query window.
:py:meth:`rtree.index.Index.intersection`

Intersection
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

Given a query window, return ids that are contained within the window:

.. code-block:: pycon

  >>> list(idx.intersection((1.0, 1.0, 2.0, 2.0)))
  [0]

Given a query window that is beyond the bounds of data we have in the
index:

.. code-block:: pycon

  >>> list(idx.intersection((1.0000001, 1.0000001, 2.0, 2.0)))
  []

Nearest Neighbors
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

The following finds the 1 nearest item to the given bounds. If multiple items
are of equal distance to the bounds, both are returned:

.. code-block:: pycon

  >>> idx.insert(1, (left, bottom, right, top))
  >>> list(idx.nearest((1.0000001, 1.0000001, 2.0, 2.0), 1))
  [0, 1]


.. _clustered:

Using Rtree as a cheapo spatial database
..............................................................................

Rtree also supports inserting any object you can pickle into the index (called
a clustered index in `libspatialindex`_ parlance). The following inserts the
picklable object ``42`` into the index with the given id ``2``:

.. code-block:: pycon

  >>> idx.insert(id=2, coordinates=(left, bottom, right, top), obj=42)

You can then return a list of objects by giving the ``objects=True`` flag
to intersection:

.. code-block:: pycon

  >>> [n.object for n in idx.intersection((left, bottom, right, top), objects=True)]
  [None, None, 42]

.. warning::
    `libspatialindex`_'s clustered indexes were not designed to be a database.
    You get none of the data integrity protections that a database would
    purport to offer, but this behavior of :ref:`Rtree <home>` can be useful
    nonetheless. Consider yourself warned. Now go do cool things with it.

Serializing your index to a file
..............................................................................

One of :ref:`Rtree <home>`'s most useful properties is the ability to
serialize Rtree indexes to disk. These include the clustered indexes
described :ref:`here <clustered>`:

.. code-block:: pycon

  >>> import os
  >>> from tempfile import TemporaryDirectory
  >>> prev_dir = os.getcwd()
  >>> temp_dir = TemporaryDirectory()
  >>> os.chdir(temp_dir.name)
  >>> file_idx = index.Rtree("myidx")
  >>> file_idx.insert(1, (left, bottom, right, top))
  >>> file_idx.insert(2, (left - 1.0, bottom - 1.0, right + 1.0, top + 1.0))
  >>> [n for n in file_idx.intersection((left, bottom, right, top))]
  [1, 2]
  >>> sorted(os.listdir())
  ['myidx.dat', 'myidx.idx']
  >>> os.chdir(prev_dir)
  >>> temp_dir.cleanup()

.. note::

    By default, if an index file with the given name ``myidx`` in the example
    above already exists on the file system, it will be opened in append mode
    and not be re-created. You can control this behavior with the
    :py:attr:`rtree.index.Property.overwrite` property of the index property
    that can be given to the :py:class:`rtree.index.Index` constructor.

.. seealso::

    :ref:`performance` describes some parameters you can tune to make
    file-based indexes run a bit faster. The choices you make for the
    parameters is entirely dependent on your usage.

Modifying file names
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Rtree uses the extensions `dat` and `idx` by default for the two index files
that are created when serializing index data to disk. These file extensions
are controllable using the :py:attr:`rtree.index.Property.dat_extension` and
:py:attr:`rtree.index.Property.idx_extension` index properties.

.. code-block:: pycon

  >>> p = index.Property()
  >>> p.dat_extension = "data"
  >>> p.idx_extension = "index"
  >>> file_idx = index.Index("rtree", properties=p)  # doctest: +SKIP

3D indexes
..............................................................................

As of Rtree version 0.5.0, you can create 3D (actually kD) indexes. The
following is a 3D index that is to be stored on disk. Persisted indexes are
stored on disk using two files -- an index file (.idx) and a data (.dat) file.
You can modify the extensions these files use by altering the properties of
the index at instantiation time. The following creates a 3D index that is
stored on disk as the files ``3d_index.data`` and ``3d_index.index``:

.. code-block:: pycon

  >>> from rtree import index
  >>> temp_dir = TemporaryDirectory()
  >>> os.chdir(temp_dir.name)
  >>> p = index.Property()
  >>> p.dimension = 3
  >>> p.dat_extension = "data"
  >>> p.idx_extension = "index"
  >>> idx3d = index.Index("3d_index", properties=p)
  >>> idx3d.insert(1, (0, 60, 23.0, 0, 60, 42.0))
  >>> list(idx3d.intersection((-1, 60, 22, 1, 62, 43)))
  [1]
  >>> os.chdir(prev_dir)
  >>> temp_dir.cleanup()

ZODB and Custom Storages
..............................................................................

https://mail.zope.org/pipermail/zodb-dev/2010-June/013491.html contains a custom
storage backend for `ZODB`_ and you can find example python code `here`_. Note
that the code was written in 2011, hasn't been updated and was only an alpha
version.

.. _`here`: https://github.com/Toblerity/zope.index.rtree
.. _`ZODB`: https://zodb.org
.. _`libspatialindex`: https://libspatialindex.org

#pragma once

using namespace System;
using namespace System::Collections::Generic;

namespace XRay 
{
	public ref class ClassRegistrator sealed
	{
	public:
		static void Register(Type^ UserClass, UInt64 BaseClassID);

		static Type^ GetTypeForClassId(UInt64 ClassID);

	private:

		static void ConditionalInitialize();

		void LoadBaseClassDefinitions();
		Dictionary<UInt64, Type^> UserDefinitions;
		Dictionary<UInt64, Type^> BaseDefinitions;

		static ClassRegistrator^ sInstance;
	};
}
